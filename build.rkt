#lang racket/base

;;; build.rkt — shared build helpers for rime-config
;;;
;;; This module is the callable build library for the app and tests.

(require racket/file
         racket/format
         racket/list
         racket/path
         racket/runtime-path
         racket/set
         racket/string
         racket/system
         "default-profile.rkt"
         "tools/yuanshu-sync.rkt")

(provide rime-dir
         output-dir
         generated-config-ids
         schema-module-ref
         read-schema-deps
         read-schema-mobile-skins
         schema-mobile-skin-module-path
         list-mobile-skin-items
         read-schema-name-from-yaml
         build-profile!
         build-profile-from-hash!
         build-profile-skin-directories!
         zip-profile-path!
         zip-profile!
         do-upload!
         deploy-desktop!
         build-preview-skins!)

;; ---- Paths -----------------------------------------------------------------

(define-runtime-path root-dir ".")
(define schema-dir   (build-path root-dir "schema"))
(define rime-dir     (build-path root-dir "rime"))
(define profiles-dir (build-path root-dir "profiles"))
(define output-dir   (build-path root-dir "output" "rime"))
(define-runtime-path mobile-lang-path "schema/lib/mobile/lang.rkt")

(define zip-exe (find-executable-path "zip"))

;; ---- Known generated IDs ---------------------------------------------------

(define generated-schema-ids '("flypy" "flypy_14" "flypy_18" "flypy_ice" "luna_pinyin" "pinyin_14" "shuffle_17" "terra_pinyin"))
(define generated-custom-ids '("cangjie6" "flypy" "jyut6ping3"))
(define generated-config-ids (remove-duplicates (append generated-schema-ids generated-custom-ids)))
(define extra-schema-ids-with-mobile '("bopomofo"))
(define generated-schema-sources
  (hash "flypy_ice" "flypy"))

;; ---- Schema module helpers -------------------------------------------------

;; Safely dynamic-require a binding from a generated schema module.
;; Returns default if the module does not exist or does not export the binding.
(define (schema-source-id schema)
  (hash-ref generated-schema-sources schema schema))

(define (schema-module-path schema)
  (build-path schema-dir (string-append (schema-source-id schema) ".rkt")))

(define (schema-module-ref schema prop [default #f])
  (define source (schema-source-id schema))
  (define rkt (schema-module-path schema))
  (if (file-exists? rkt)
      (if (equal? source schema)
          (dynamic-require rkt prop (lambda () default))
          (let ([meta (dynamic-require rkt 'schema-meta (lambda () #f))])
            (if (hash? meta)
                (hash-ref (hash-ref meta schema (hash)) prop default)
                default)))
      default))

(define (schema-mobile-skin-body schema skin)
  (define skin-defs (schema-module-ref schema 'mobile-skin-defs '()))
  (cond
    [(assoc skin skin-defs) => cdr]
    [else #f]))

(define (write-skin-module! schema skin body)
  (define out-dir (build-path (find-system-path 'temp-dir) "rime-config-schema-skins"))
  (make-directory* out-dir)
  (define path (build-path out-dir (format "~a-~a.rkt" schema skin)))
  (call-with-output-file path
    #:exists 'truncate/replace
    (lambda (out)
      (fprintf out "#lang s-exp (file ~s)\n" (path->string mobile-lang-path))
      (write `(skin ,(string->symbol skin)
               (triggers ,(string->symbol schema))
               ,@body)
             out)
      (newline out)))
  path)

(define (schema-mobile-skin-module-path skin schemas)
  (define search-schemas
    (remove-duplicates (append schemas generated-config-ids extra-schema-ids-with-mobile)))
  (for/or ([schema (in-list search-schemas)])
    (define body (schema-mobile-skin-body schema skin))
    (and body (write-skin-module! schema skin body))))

(define (list-mobile-skin-items schemas)
  (define search-schemas
    (remove-duplicates (append schemas generated-config-ids extra-schema-ids-with-mobile)))
  (for*/list ([schema (in-list search-schemas)]
              [skin (in-list (read-schema-mobile-skins schema))]
              #:do [(define body (schema-mobile-skin-body schema skin))]
              #:when body)
    (list schema skin (write-skin-module! schema skin body))))

;; ---- Utilities -------------------------------------------------------------

(define (run! prog . args)
  (define str-args (map (lambda (a) (if (path? a) (path->string a) (~a a))) args))
  (unless (apply system* prog str-args)
    (error 'build "Command failed: ~a ~a" prog str-args)))

(define (delete-file* p)
  (when (file-exists? p) (delete-file p)))

(define (copy-file! src dst)
  (make-directory* (path-only dst))
  (copy-file src dst #t))

(define (copy-dir! src dst)
  (when (directory-exists? dst) (delete-directory/files dst))
  (copy-directory/files src dst))

;; ---- Recursive file listing ------------------------------------------------

(define (list-files-relative dir)
  ;; Returns a list of relative path strings for all files under dir.
  (let loop ([base dir] [prefix ""])
    (append-map
     (lambda (entry)
       (define full (build-path base entry))
       (define rel  (if (string=? prefix "")
                        (path->string entry)
                        (string-append prefix "/" (path->string entry))))
       (cond
         [(file-exists?      full) (list rel)]
         [(directory-exists? full) (loop full rel)]
         [else '()]))
     (directory-list base))))

;; ---- Profile loading -------------------------------------------------------

(define yuanshu-profiles-dir (build-path profiles-dir "yuanshu"))

(define all-mobile-profile
  (hash 'schemas "all"
        'skip-default-custom #t))

(define (find-profile-path name)
  (for/or ([base (list profiles-dir
                       yuanshu-profiles-dir
                       (build-path profiles-dir "customer")
                       (build-path yuanshu-profiles-dir "customer"))])
    (define p (build-path base (string-append name ".rkt")))
    (and (file-exists? p) p)))

(define (load-profile name)
  (define path (or (find-profile-path name)
                   (error 'build "Profile '~a' not found" name)))
  (dynamic-require path 'profile))

(define (named-rime-profile name)
  (cond
    [(equal? name "desktop") default-desktop-profile]
    [(equal? name "all") all-mobile-profile]
    [else (load-profile name)]))

;; ---- Schema dependency expansion -------------------------------------------

(define (read-schema-deps-from-yaml schema)
  (define yaml-path
    (for/or ([base (list rime-dir root-dir)])
      (define p (build-path base (string-append schema ".schema.yaml")))
      (and (file-exists? p) p)))
  (if (not yaml-path)
      '()
      (call-with-input-file yaml-path
        (lambda (in)
          (let loop ([in-deps? #f] [acc '()])
            (define line (read-line in))
            (cond
              [(eof-object? line) (reverse acc)]
              [(regexp-match? #rx"^  dependencies:" line)
               (loop #t acc)]
              [(and in-deps? (regexp-match #rx"^    - (.+)" line))
               => (lambda (m) (loop #t (cons (string-trim (cadr m)) acc)))]
              [in-deps? (reverse acc)]
              [else (loop #f acc)]))))))

(define (read-schema-name-from-yaml schema)
  (define yaml-path
    (for/or ([base (list rime-dir root-dir)])
      (define p (build-path base (string-append schema ".schema.yaml")))
      (and (file-exists? p) p)))
  (if (not yaml-path)
      #f
      (call-with-input-file yaml-path
        (lambda (in)
          (let loop ()
            (define line (read-line in))
            (cond
              [(eof-object? line) #f]
              [(regexp-match #rx"^  name: \"?([^\"]+)\"?" line)
               => (lambda (m) (string-trim (cadr m)))]
              [else (loop)]))))))

;; For generated schemas, read deps from the module; fall back to YAML for static ones.
(define (read-schema-deps schema)
  (schema-module-ref schema 'schema-deps
                     (read-schema-deps-from-yaml schema)))

(define (read-schema-mobile-skins schema)
  (define skins (schema-module-ref schema 'mobile-skins '()))
  (cond
    [(not skins) '()]
    [(list? skins) skins]
    [else (list skins)]))

(define (list-static-schema-ids)
  (filter-map
   (lambda (f)
     (define name (path->string f))
     (and (regexp-match? #rx"\\.schema\\.yaml$" name)
          (regexp-replace #rx"\\.schema\\.yaml$" name "")))
   (directory-list rime-dir)))

(define (profile-schema-list profile)
  (define raw (hash-ref profile 'schemas '()))
  (define lst (if (list? raw) raw (list raw)))
  (if (member "all" lst)
      (remove-duplicates (append generated-config-ids (list-static-schema-ids)))
      lst))

(define (expand-schema-deps schemas)
  (let loop ([queue schemas] [resolved '()])
    (if (null? queue)
        (reverse resolved)
        (let ([s (car queue)])
          (if (member s resolved)
              (loop (cdr queue) resolved)
              (loop (append (cdr queue)
                            (filter (lambda (d) (not (member d resolved)))
                                    (read-schema-deps s)))
                    (cons s resolved)))))))

;; ---- Input validation ------------------------------------------------------

(define (valid-schema-id? s)
  (and (string? s) (regexp-match? #rx"^[a-zA-Z0-9_-]+$" s)))

;; ---- Resolve schemas from profile ------------------------------------------

(define (resolve-schemas profile)
  (define raw
    (let ([lst (profile-schema-list profile)])
      (for ([id lst])
        (unless (valid-schema-id? id)
          (error 'resolve-schemas "Invalid schema id: ~v" id)))
      lst))

  (define expanded (expand-schema-deps raw))

  (define desktop? (hash-ref profile 'desktop? #f))
  (define filtered
    (if desktop?
        (filter (lambda (s) (not (schema-module-ref s 'mobile-only? #f))) expanded)
        expanded))

  (remove-duplicates filtered))

;; ---- Compute file lists from schemas ---------------------------------------
;; Returns: gen-yaml (built by build-configs!, already in profile-out)
;;          rime-yaml (static files to copy from rime-dir)
;;          rime-dirs (static dirs to copy from rime-dir)
;;          skins

(define (compute-assets schemas profile)
  (define extra-rime  (hash-ref profile 'extra-src-files  '()))
  (define selected-mobile-skins
    (append-map read-schema-mobile-skins (profile-schema-list profile)))

  (define gen-yaml  '())
  (define rime-yaml '())
  (define rime-dirs '())
  (define skins     '())

  (define (add-gen!       f) (set! gen-yaml  (cons f gen-yaml)))
  (define (add-rime-yaml! f) (set! rime-yaml (cons f rime-yaml)))
  (define (add-rime-dir!  d) (set! rime-dirs (cons d rime-dirs)))
  (define (add-skin!      s) (set! skins     (cons s skins)))

  ;; Per-schema: schema file + custom file
  (for ([schema schemas])
    (cond
      [(member schema generated-schema-ids)
       (add-gen! (string-append schema ".schema.yaml"))]
      [(file-exists? (build-path rime-dir (string-append schema ".schema.yaml")))
       (add-rime-yaml! (string-append schema ".schema.yaml"))])
    (cond
      [(member schema generated-config-ids)
       (add-gen! (string-append schema ".custom.yaml"))]
      [(file-exists? (build-path rime-dir (string-append schema ".custom.yaml")))
       (add-rime-yaml! (string-append schema ".custom.yaml"))]))

  ;; Schema-specific static extras: generated schemas declare their own deps.
  (for ([schema schemas])
    (for ([f (schema-module-ref schema 'static-dep-files '())]) (add-rime-yaml! f))
    (for ([d (schema-module-ref schema 'static-dep-dirs  '())]) (add-rime-dir!  d)))

  ;; Static-only schemas (no .rkt) declare their deps here.
  (when (member "luna_pinyin"  schemas) (add-rime-yaml! "luna_pinyin.dict.yaml")
                                        (add-rime-yaml! "zhuyin.yaml"))
  (when (member "terra_pinyin" schemas) (add-rime-yaml! "terra_pinyin.dict.yaml"))
  (when (member "bopomofo"     schemas) (add-rime-yaml! "terra_pinyin.dict.yaml")
                                        (add-rime-yaml! "zhuyin.yaml"))

  ;; yuanshu_shared is generated by build-configs!
  (add-gen! "yuanshu_shared.yaml")

  ;; Extra static files from profile (e.g. squirrel.custom.yaml)
  (for ([f extra-rime]) (add-rime-yaml! f))

  ;; Mobile skins are schema metadata, so profiles only need schema config.
  (unless (hash-ref profile 'desktop? #f)
    (for ([s selected-mobile-skins]) (add-skin! s)))

  (values (remove-duplicates (reverse gen-yaml))
          (remove-duplicates (reverse rime-yaml))
          (remove-duplicates (reverse rime-dirs))
          (remove-duplicates (reverse skins))))

;; ---- Write files from a module's exported hash ----------------------------

(define (module-export-ref rkt-path export-sym #:fresh? [fresh? #f])
  (if fresh?
      (parameterize ([current-namespace (make-base-namespace)])
        (dynamic-require rkt-path export-sym))
      (dynamic-require rkt-path export-sym)))

(define (write-module-files! rkt-path out-dir export-sym #:fresh? [fresh? #f])
  (define files
    (let ([v (module-export-ref rkt-path export-sym #:fresh? fresh?)])
      (unless (hash? v)
        (error 'write-module-files!
               "~a: expected ~a to be a hash, got ~v" rkt-path export-sym v))
      v))
  (for ([(rel-path content) (in-hash files)])
    (define target (build-path out-dir (string->path rel-path)))
    (make-directory* (path-only target))
    (call-with-output-file target #:exists 'truncate/replace
      (lambda (out)
        (cond
          [(string? content) (display content out)]
          [(bytes?  content) (write-bytes content out)]
          [else (error 'write-module-files!
                       "~a: expected string or bytes for ~a, got ~v"
                       rkt-path rel-path content)])))))

(define (with-skin-doc-rendering enabled? thunk)
  (define previous (getenv "RIME_RENDER_SKIN_DOCS"))
  (dynamic-wind
    (lambda ()
      (when enabled?
        (putenv "RIME_RENDER_SKIN_DOCS" "1")))
    thunk
    (lambda ()
      (if previous
          (putenv "RIME_RENDER_SKIN_DOCS" previous)
          (putenv "RIME_RENDER_SKIN_DOCS" "")))))

;; ---- Build schemas ---------------------------------------------------------

(define (build-schemas! schemas profile-out)
  (define needed
    (list->set
     (cons "yuanshu_shared.rkt"
           (map (lambda (s) (string-append (schema-source-id s) ".rkt")) schemas))))
  (define entrypoints
    (sort
     (filter (lambda (p)
               (set-member? needed (path->string (file-name-from-path p))))
             (directory-list schema-dir #:build? #t))
     path<?))
  (for ([f entrypoints])
    (define schema-config-files
      (dynamic-require f 'schema-config-files (lambda () #f)))
    (if (hash? schema-config-files)
        (for ([schema (in-list schemas)]
              #:when (equal? (path->string (file-name-from-path f))
                             (string-append (schema-source-id schema) ".rkt")))
          (define files
            (hash-ref schema-config-files schema
                      (lambda ()
                        (error 'build-schemas!
                               "~a: missing generated config for ~a"
                               f
                               schema))))
          (for ([(rel-path content) (in-hash files)])
            (define target (build-path profile-out (string->path rel-path)))
            (make-directory* (path-only target))
            (call-with-output-file target #:exists 'truncate/replace
              (lambda (out)
                (cond
                  [(string? content) (display content out)]
                  [(bytes? content) (write-bytes content out)]
                  [else (error 'build-schemas!
                               "~a: expected string or bytes for ~a, got ~v"
                               f
                               rel-path
                               content)])))))
        (write-module-files! f profile-out 'config-files))))

;; ---- Build skins -----------------------------------------------------------

(define (skin-module-path! skin schemas)
  (define skin-rkt
    (or (schema-mobile-skin-module-path skin schemas)
        (error 'build-one-skin! "No mobile skin definition for ~a" skin)))
  skin-rkt)

(define (write-unpacked-skin! skin-rkt out-dir)
  (make-directory* out-dir)
  ;; Runtime uploads only need skin files; preview docs are built separately.
  (write-module-files! skin-rkt
                       out-dir
                       'skin-preview-files
                       #:fresh? #t))

(define (build-one-skin! skin schemas profile-name profile-out)
  (define skin-rkt (skin-module-path! skin schemas))
  (define safe-profile-name
    (regexp-replace* #rx"[^a-zA-Z0-9._-]+" profile-name "_"))
  (define tmp-dir  (build-path (path-only profile-out) (string-append "tmp-" safe-profile-name)))
  (define tmp-skin (build-path tmp-dir skin))
  (define cskin    (build-path profile-out "skins" (string-append skin ".cskin")))
  (printf "Building skin: ~a\n" skin)
  (delete-directory/files tmp-dir #:must-exist? #f)
  (write-unpacked-skin! skin-rkt tmp-skin)
  (delete-file* cskin)
  (parameterize ([current-directory tmp-dir])
    (run! zip-exe "-qr" (path->string cskin) skin))
  (delete-directory/files tmp-dir))

(define (build-skins! skins schemas profile-name profile-out)
  (unless (null? skins)
    (make-directory* (build-path profile-out "skins"))
    (for ([skin skins])
      (build-one-skin! skin schemas profile-name profile-out))))

(define (build-unpacked-skins! skins schemas out-dir)
  (delete-directory/files out-dir #:must-exist? #f)
  (make-directory* out-dir)
  (for ([skin (in-list skins)])
    (printf "Building skin folder: ~a\n" skin)
    (write-unpacked-skin! (skin-module-path! skin schemas)
                          (build-path out-dir skin))))

(define (build-profile-skin-directories! profile profile-name out-dir)
  (define schemas (resolve-schemas profile))
  (define-values (_gen-yaml _rime-yaml _rime-dirs skins)
    (compute-assets schemas profile))
  (build-unpacked-skins! skins schemas out-dir)
  skins)

;; ---- Build one profile -----------------------------------------------------

(define (build-profile-from-hash! profile profile-name profile-out)
  (delete-directory/files profile-out #:must-exist? #f)
  (make-directory* profile-out)

  (define schemas (resolve-schemas profile))
  (printf "Building '~a': ~a\n" profile-name (string-join schemas " "))

  (build-schemas! schemas profile-out)

  (define-values (_gen-yaml rime-yaml rime-dirs skins)
    (compute-assets schemas profile))

  ;; Copy static YAML files from rime-dir
  (for ([f rime-yaml])
    (define src (build-path rime-dir f))
    (when (file-exists? src)
      (copy-file! src (build-path profile-out f))))

  ;; Copy static directories from rime-dir
  (for ([d rime-dirs])
    (define src (build-path rime-dir d))
    (when (directory-exists? src)
      (copy-dir! src (build-path profile-out d))))

  ;; default.custom.yaml
  (define default-custom (build-path profile-out "default.custom.yaml"))
  (if (not (hash-ref profile 'skip-default-custom #f))
      (let* ([raw (hash-ref profile 'schemas '())]
             [display-schemas
              (if (or (equal? raw "all")
                      (and (list? raw) (member "all" raw)))
                  schemas
                  (if (list? raw) raw (list raw)))])
        (call-with-output-file default-custom #:exists 'truncate/replace
          (lambda (out)
            (displayln "patch:" out)
            (displayln "  schema_list:" out)
            (for ([s display-schemas])
              (fprintf out "    - schema: ~a\n" s)))))
      (delete-file* default-custom))

  (build-skins! skins schemas profile-name profile-out))

(define (build-profile! profile-name)
  (define profile     (named-rime-profile profile-name))
  (define profile-out (build-path output-dir profile-name))
  (build-profile-from-hash! profile profile-name profile-out))

;; ---- Zip -------------------------------------------------------------------

(define (zip-profile-path! profile-name profile-out zip-path)
  (delete-file* zip-path)
  (make-directory* (path-only zip-path))
  (parameterize ([current-directory (path-only zip-path)])
    (run! zip-exe "-qr"
          (path->string (file-name-from-path zip-path))
          (path->string (file-name-from-path profile-out))))
  (printf "Packaged: ~a\n" zip-path))

(define (zip-profile! profile-name)
  (define zip-path (build-path output-dir (string-append profile-name ".zip")))
  (define profile-out (build-path output-dir profile-name))
  (zip-profile-path! profile-name profile-out zip-path))


;; ---- Upload ----------------------------------------------------------------

(define (do-upload! src-dir
                    #:remote-root     [remote-root "/RimeUserData/rime/"]
                    #:base-url        [base-url #f]
                    #:skin-source-dir [skin-source-dir #f]
                    #:allow-delete    [allow-delete #f]
                    #:include-big-dicts [include-big-dicts #t]
                    #:dry-run         [dry-run #f]
                    #:progress        [progress (lambda (_line) (void))])
  (define exclude-dirs
    (if include-big-dicts '() '("jyut6ping3_dicts" "rime_ice_dicts")))
  (parameterize ([current-yuanshu-sync-log progress])
    (sync-yuanshu-bundle! src-dir
                          #:remote-root remote-root
                          #:base-url base-url
                          #:allow-delete? allow-delete
                          #:dry-run? dry-run
                          #:exclude-dirs exclude-dirs)
    (when skin-source-dir
      (progress "Refreshing selected Yuanshu /Skins/ folders...")
      (sync-yuanshu-skins! skin-source-dir
                           #:remote-root "/Skins/"
                           #:base-url base-url
                           #:dry-run? dry-run))))

;; ---- Deploy desktop config -------------------------------------------------
;; Builds the desktop profile then syncs to the live Rime directory.
;; Never touches *.userdb, user.yaml, installation.yaml, *.bin, sync/.

(define squirrel-binary
  "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel")

;; Patterns of files/dirs in ~/Library/Rime that we must never touch.
(define rime-protected-rx
  (list #rx"\\.userdb(/|$)"       ; learned word databases
        #rx"(^|/)user\\.yaml$"    ; rime session state
        #rx"(^|/)installation\\.yaml$" ; rime installation config
        #rx"\\.bin$"              ; compiled binary data
        #rx"(^|/)sync(/|$)"       ; rime sync directory
        #rx"(^|/)build(/|$)"))

(define (rime-protected? rel-path)
  (define s (if (path? rel-path) (path->string rel-path) rel-path))
  (ormap (lambda (rx) (regexp-match? rx s)) rime-protected-rx))

;; Extensions we own and may delete when syncing.
(define rime-managed-exts '(".yaml" ".txt"))

(define (rime-managed? rel-path)
  (define s (if (path? rel-path) (path->string rel-path) rel-path))
  (ormap (lambda (ext) (string-suffix? s ext)) rime-managed-exts))

(define (sync-to-dir! build-out target-dir)
  (define deploy-set (list->set (list-files-relative build-out)))

  ;; Delete managed files in target that are no longer in our build output.
  (for ([rel (list-files-relative target-dir)])
    (when (and (rime-managed? rel)
               (not (rime-protected? rel))
               (not (set-member? deploy-set rel)))
      (define victim (build-path target-dir rel))
      (printf "Removing stale: ~a\n" rel)
      (delete-file victim)))

  ;; Copy all build-output files to target.
  (for ([rel (set->list deploy-set)])
    (copy-file! (build-path build-out rel)
                (build-path target-dir rel))))

(define (rime-deploy!)
  (cond
    [(file-exists? squirrel-binary)
     (printf "Triggering Rime deployment...\n")
     (unless (system* squirrel-binary "--reload")
       (eprintf "Warning: Rime deploy command exited with error\n"))]
    [else
     (eprintf "Warning: Squirrel not found at ~a — skipping Rime deploy\n" squirrel-binary)]))

(define (deploy-desktop! target-dir #:rime-deploy? [rime-deploy? #t])
  (when (equal? (normalize-path root-dir)
                (normalize-path target-dir))
    (error 'deploy "target is the same as the repo root — aborting"))

  ;; Build desktop profile into build/desktop/
  (define build-out (build-path output-dir "desktop"))
  (build-profile-from-hash! default-desktop-profile "desktop" build-out)

  (make-directory* target-dir)
  (sync-to-dir! build-out target-dir)
  (printf "Deployed to ~a\n" (path->string target-dir))

  (when rime-deploy? (rime-deploy!)))

;; ---- Standalone skin previews ----------------------------------------------

(define (build-preview-skins! #:render-docs? [render-docs? #f])
  (define schemas (remove-duplicates (append generated-config-ids (list-static-schema-ids))))
  (for ([item (in-list (list-mobile-skin-items schemas))])
    (define skin (cadr item))
    (define skin-file (caddr item))
    (define out  (build-path output-dir "compiled-skins" skin))
    (printf "Building preview skin: ~a~a\n" skin (if render-docs? " (with docs)" ""))
    (delete-directory/files out #:must-exist? #f)
    (make-directory* out)
    (with-skin-doc-rendering
     #t
     (lambda ()
       (write-module-files! skin-file
                            out
                            (if render-docs? 'skin-files 'skin-preview-build-files))))))
