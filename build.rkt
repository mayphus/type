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
         "schema/registry.rkt"
         "tools/yuanshu-sync.rkt")

(provide rime-dir
         output-dir
         generated-config-ids
         schema-module-ref
         keyboard-layout-module-ref
         skin-module-ref
         read-schema-deps
         read-schema-artifacts
         read-schema-keyboard-layouts
         read-schema-mobile-skins
         schema-keyboard-layout-module-path
         schema-mobile-skin-module-path
         list-keyboard-layout-items
         list-mobile-skin-items
         read-schema-name-from-yaml
         read-schema-description
         profile-artifact
         build-profile!
         build-profile-from-hash!
         build-profile-keyboard-layout-directories!
         build-profile-skin-directories!
         build-bundle!
         zip-profile-path!
         zip-profile!
         do-upload!
         deploy-desktop!
         build-preview-keyboard-layouts!
         build-preview-skins!)

;; ---- Paths -----------------------------------------------------------------

(define-runtime-path root-dir ".")
(define schema-dir   (build-path root-dir "schema"))
(define rime-dir     (build-path root-dir "rime"))
(define profiles-dir (build-path root-dir "profiles"))
(define output-dir   (build-path root-dir "output" "rime"))
(define-runtime-path mobile-lang-path "schema/lib/mobile/lang.rkt")

(define zip-exe (find-executable-path "zip"))

(struct keyboard-layout-module (schema layout body) #:transparent)

(define keyboard-layout-module-namespace (make-base-namespace))
(define declared-keyboard-layout-modules (mutable-set))

(define (keyboard-layout-runtime-module-name schema layout)
  (string->symbol (format "rime-config-keyboard-layout-~a-~a" schema layout)))

(define (declare-keyboard-layout-module! mod ns)
  (define name
    (keyboard-layout-runtime-module-name
     (keyboard-layout-module-schema mod)
     (keyboard-layout-module-layout mod)))
  (unless (and (eq? ns keyboard-layout-module-namespace)
               (set-member? declared-keyboard-layout-modules name))
    (parameterize ([current-namespace ns])
      (eval `(module ,name
               (file ,(path->string mobile-lang-path))
               (keyboard-layout ,(string->symbol (keyboard-layout-module-layout mod))
                 (triggers ,(string->symbol (keyboard-layout-module-schema mod)))
                 ,@(keyboard-layout-module-body mod)))))
    (when (eq? ns keyboard-layout-module-namespace)
      (set-add! declared-keyboard-layout-modules name))))

(define (keyboard-layout-module-ref mod export-sym [default-thunk #f] #:fresh? [fresh? #f])
  (define ns (if fresh? (make-base-namespace) keyboard-layout-module-namespace))
  (declare-keyboard-layout-module! mod ns)
  (parameterize ([current-namespace ns])
    (if default-thunk
        (dynamic-require
         `',(keyboard-layout-runtime-module-name
             (keyboard-layout-module-schema mod)
             (keyboard-layout-module-layout mod))
         export-sym
         default-thunk)
        (dynamic-require
         `',(keyboard-layout-runtime-module-name
             (keyboard-layout-module-schema mod)
             (keyboard-layout-module-layout mod))
         export-sym))))

(define skin-module-ref keyboard-layout-module-ref)

;; ---- Schema module helpers -------------------------------------------------

;; Safely dynamic-require a binding from a generated schema module.
;; Returns default if the module does not exist or does not export the binding.
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

(define (schema-keyboard-layout-body schema layout)
  (define layout-defs (schema-module-ref schema 'keyboard-layout-defs
                                         (schema-module-ref schema 'mobile-skin-defs '())))
  (cond
    [(assoc layout layout-defs) => cdr]
    [else #f]))

(define (schema-mobile-skin-body schema skin)
  (schema-keyboard-layout-body schema skin))

(define (schema-keyboard-layout-module schema layout body)
  (keyboard-layout-module schema layout body))

(define (schema-mobile-skin-module schema skin body)
  (schema-keyboard-layout-module schema skin body))

(define (schema-keyboard-layout-module-path layout schemas)
  (define search-schemas
    (remove-duplicates (append schemas generated-config-ids extra-schema-ids-with-mobile)))
  (for/or ([schema (in-list search-schemas)])
    (define body (schema-keyboard-layout-body schema layout))
    (and body (schema-keyboard-layout-module schema layout body))))

(define (schema-mobile-skin-module-path skin schemas)
  (schema-keyboard-layout-module-path skin schemas))

(define (list-keyboard-layout-items schemas)
  (define search-schemas
    (remove-duplicates (append schemas generated-config-ids extra-schema-ids-with-mobile)))
  (for*/list ([schema (in-list search-schemas)]
              [layout (in-list (read-schema-keyboard-layouts schema))]
              #:do [(define body (schema-keyboard-layout-body schema layout))]
              #:when body)
    (list schema layout (schema-keyboard-layout-module schema layout body))))

(define list-mobile-skin-items list-keyboard-layout-items)

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
        'artifact "yuanshu"
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

(define (read-schema-name-from-yaml schema)
  (static-schema-name schema))

(define (read-schema-description schema)
  (schema-module-ref schema 'schema-summary
                     (static-schema-description schema)))

;; For generated schemas, read deps from the module; fall back to registry
;; metadata for static imported schemas.
(define (read-schema-deps schema)
  (schema-module-ref schema 'schema-deps
                     (static-schema-deps schema)))

(define (read-schema-artifacts schema)
  (define artifacts (schema-module-ref schema 'schema-artifacts
                                       (static-schema-artifacts schema)))
  (cond
    [(not artifacts) '()]
    [(list? artifacts) artifacts]
    [else (list artifacts)]))

(define (read-schema-keyboard-layouts schema)
  (define layouts (schema-module-ref schema 'keyboard-layouts
                                     (schema-module-ref schema 'mobile-skins '())))
  (cond
    [(not layouts) '()]
    [(list? layouts) layouts]
    [else (list layouts)]))

(define read-schema-mobile-skins read-schema-keyboard-layouts)

(define (schema-supports-artifact? schema artifact)
  (member artifact (read-schema-artifacts schema)))

(define (profile-artifact profile)
  (define artifact (hash-ref profile 'artifact #f))
  (cond
    [(or (equal? artifact "rime") (equal? artifact 'rime)) "rime"]
    [(or (equal? artifact "yuanshu") (equal? artifact 'yuanshu)) "yuanshu"]
    [(hash-has-key? profile 'desktop?)
     (if (hash-ref profile 'desktop? #f) "rime" "yuanshu")]
    [else "rime"]))

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

  (define artifact (profile-artifact profile))
  (define filtered
    (filter (lambda (s) (schema-supports-artifact? s artifact)) expanded))

  (remove-duplicates filtered))

;; ---- Compute file lists from schemas ---------------------------------------
;; Returns: gen-yaml (built by build-configs!, already in profile-out)
;;          rime-yaml (static files to copy from rime-dir)
;;          rime-dirs (static dirs to copy from rime-dir)
;;          keyboard layouts

(define (compute-assets schemas profile)
  (define extra-rime  (hash-ref profile 'extra-src-files  '()))
  (define selected-keyboard-layouts
    (append-map read-schema-keyboard-layouts (profile-schema-list profile)))
  (define artifact (profile-artifact profile))

  (define gen-yaml  '())
  (define rime-yaml '())
  (define rime-dirs '())
  (define keyboard-layouts '())

  (define (add-gen!       f) (set! gen-yaml  (cons f gen-yaml)))
  (define (add-rime-yaml! f) (set! rime-yaml (cons f rime-yaml)))
  (define (add-rime-dir!  d) (set! rime-dirs (cons d rime-dirs)))
  (define (add-keyboard-layout! layout)
    (set! keyboard-layouts (cons layout keyboard-layouts)))

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
    (for ([f (static-schema-extra-files schema)]) (add-rime-yaml! f))
    (for ([d (schema-module-ref schema 'static-dep-dirs  '())]) (add-rime-dir!  d))
    (for ([d (static-schema-extra-dirs schema)]) (add-rime-dir! d)))

  ;; yuanshu_shared is generated by build-configs!
  (add-gen! "yuanshu_shared.yaml")

  ;; Extra static files from profile (e.g. squirrel.custom.yaml)
  (for ([f extra-rime]) (add-rime-yaml! f))

  ;; Yuanshu keyboard layouts are schema metadata, so profiles only need schema config.
  (when (equal? artifact "yuanshu")
    (for ([layout selected-keyboard-layouts]) (add-keyboard-layout! layout)))

  (values (remove-duplicates (reverse gen-yaml))
          (remove-duplicates (reverse rime-yaml))
          (remove-duplicates (reverse rime-dirs))
          (remove-duplicates (reverse keyboard-layouts))))

;; ---- Write files from a module's exported hash ----------------------------

(define (module-export-ref rkt-path export-sym #:fresh? [fresh? #f])
  (if (keyboard-layout-module? rkt-path)
      (keyboard-layout-module-ref rkt-path export-sym #:fresh? fresh?)
      (if fresh?
          (parameterize ([current-namespace (make-base-namespace)])
            (dynamic-require rkt-path export-sym))
          (dynamic-require rkt-path export-sym))))

(define (write-module-files! rkt-path out-dir export-sym #:fresh? [fresh? #f])
  (define files
    (let ([v (module-export-ref rkt-path export-sym #:fresh? fresh?)])
      (unless (hash? v)
        (unless (procedure? v)
          (error 'write-module-files!
                 "~a: expected ~a to be a hash or thunk, got ~v" rkt-path export-sym v)))
      (if (procedure? v) (v) v)))
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

;; ---- Build keyboard layouts ------------------------------------------------

(define (keyboard-layout-module-path! layout schemas)
  (or (schema-keyboard-layout-module-path layout schemas)
      (error 'build-one-keyboard-layout!
             "No keyboard layout definition for ~a"
             layout)))

(define (skin-module-path! skin schemas)
  (keyboard-layout-module-path! skin schemas))

(define (write-unpacked-keyboard-layout! layout-rkt out-dir #:with-docs? [with-docs? #f])
  (make-directory* out-dir)
  (write-module-files! layout-rkt
                       out-dir
                       (if with-docs?
                           'keyboard-layout-files-with-docs
                           'keyboard-layout-files)
                       #:fresh? with-docs?))

(define (write-unpacked-skin! skin-rkt out-dir #:with-docs? [with-docs? #f])
  (write-unpacked-keyboard-layout! skin-rkt out-dir #:with-docs? with-docs?))

(define (build-one-keyboard-layout! layout schemas profile-out layout-root)
  (define layout-rkt (keyboard-layout-module-path! layout schemas))
  (define layout-out (build-path layout-root layout))
  ;; The profile ZIP keeps Yuanshu's required `skins/*.cskin` package contract.
  (define cskin (build-path profile-out "skins" (string-append layout ".cskin")))
  (printf "Building keyboard layout: ~a\n" layout)
  (delete-directory/files layout-out #:must-exist? #f)
  (write-unpacked-keyboard-layout! layout-rkt layout-out #:with-docs? #t)
  (delete-file* cskin)
  (make-directory* (path-only cskin))
  (parameterize ([current-directory layout-root])
    (run! zip-exe "-qr" (path->string cskin) layout))
  layout-out)

(define (build-one-skin! skin schemas profile-out skin-root)
  (build-one-keyboard-layout! skin schemas profile-out skin-root))

(define (build-keyboard-layouts! layouts schemas profile-out layout-root)
  (unless (null? layouts)
    (make-directory* (build-path profile-out "skins"))
    (delete-directory/files layout-root #:must-exist? #f)
    (make-directory* layout-root)
    (for ([layout layouts])
      (build-one-keyboard-layout! layout schemas profile-out layout-root))))

(define build-skins! build-keyboard-layouts!)

(define (build-profile-keyboard-layout-directories! profile profile-name out-dir)
  (define tmp-dir (make-temporary-file "rime-layout-profile-~a" 'directory))
  (dynamic-wind
    void
    (lambda ()
      (build-profile-from-hash! profile
                                profile-name
                                (build-path tmp-dir profile-name)
                                #:keyboard-layout-dir out-dir))
    (lambda ()
      (delete-directory/files tmp-dir #:must-exist? #f)))
  (define-values (_gen-yaml _rime-yaml _rime-dirs layouts)
    (compute-assets (resolve-schemas profile) profile))
  layouts)

(define build-profile-skin-directories! build-profile-keyboard-layout-directories!)

;; ---- Build one bundle ------------------------------------------------------

(define (build-profile-from-hash! profile profile-name profile-out
                                  #:keyboard-layout-dir [keyboard-layout-dir #f]
                                  #:skin-dir [skin-dir #f])
  (delete-directory/files profile-out #:must-exist? #f)
  (make-directory* profile-out)

  (define schemas (resolve-schemas profile))
  (printf "Building '~a': ~a\n" profile-name (string-join schemas " "))

  (build-schemas! schemas profile-out)

  (define-values (_gen-yaml rime-yaml rime-dirs keyboard-layouts)
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
             [raw-list (if (list? raw) raw (list raw))]
             [display-schemas
              (if (or (equal? raw "all")
                      (and (list? raw) (member "all" raw)))
                  schemas
                  (let ([filtered
                         (filter (lambda (s)
                                   (member s schemas))
                                 raw-list)])
                    (if (null? filtered) schemas filtered)))])
        (call-with-output-file default-custom #:exists 'truncate/replace
          (lambda (out)
            (displayln "patch:" out)
            (displayln "  schema_list:" out)
            (for ([s display-schemas])
              (fprintf out "    - schema: ~a\n" s)))))
      (delete-file* default-custom))

  (define tmp-layout-dir #f)
  (define layout-root
    (or keyboard-layout-dir
        skin-dir
        (and (pair? keyboard-layouts)
             (begin
               (set! tmp-layout-dir (make-temporary-file "rime-layouts-~a" 'directory))
               tmp-layout-dir))))
  (when layout-root
    (build-keyboard-layouts! keyboard-layouts schemas profile-out layout-root))
  (when tmp-layout-dir
    (delete-directory/files tmp-layout-dir #:must-exist? #f)))

(define (build-bundle! profile
                       profile-name
                       profile-out
                       zip-path
                       #:keyboard-layout-dir [keyboard-layout-dir 'auto]
                       #:skin-dir [skin-dir 'auto])
  (define requested-layout-dir
    (if (eq? keyboard-layout-dir 'auto) skin-dir keyboard-layout-dir))
  (define final-layout-dir
    (cond
      [(eq? requested-layout-dir 'auto)
       (build-path (path-only profile-out)
                   (string-append (path->string (file-name-from-path profile-out)) "-layouts"))]
      [else requested-layout-dir]))
  (build-profile-from-hash! profile
                            profile-name
                            profile-out
                            #:keyboard-layout-dir final-layout-dir)
  (zip-profile-path! profile-name profile-out zip-path)
  (values profile-out zip-path final-layout-dir))

(define (build-profile! profile-name)
  (define profile     (named-rime-profile profile-name))
  (define profile-out (build-path output-dir profile-name))
  (build-profile-from-hash! profile profile-name profile-out))

;; ---- ZIP archives -----------------------------------------------------------

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

;; ---- Standalone keyboard layout previews -----------------------------------

(define (build-preview-keyboard-layouts! #:render-docs? [render-docs? #f])
  (define schemas (remove-duplicates (append generated-config-ids (list-static-schema-ids))))
  (for ([item (in-list (list-keyboard-layout-items schemas))])
    (define layout (cadr item))
    (define layout-file (caddr item))
    (define out (build-path output-dir "compiled-keyboard-layouts" layout))
    (printf "Building preview keyboard layout: ~a~a\n" layout (if render-docs? " (with docs)" ""))
    (delete-directory/files out #:must-exist? #f)
    (make-directory* out)
    (write-module-files! layout-file
                         out
                         (if render-docs?
                             'keyboard-layout-files-with-docs
                             'keyboard-layout-files)
                         #:fresh? render-docs?)))

(define build-preview-skins! build-preview-keyboard-layouts!)
