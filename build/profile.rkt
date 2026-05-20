#lang racket/base

(require racket/file
         racket/list
         racket/path
         racket/set
         racket/string
         "../core/input-methods.rkt"
         "keyboard.rkt"
         "paths.rkt"
         "schema.rkt"
         "util.rkt"
         "writer.rkt")

(provide build-profile!
         build-profile-from-hash!
         build-profile-keyboard-layout-directories!
         build-profile-skin-directories!
         build-output!
         build-bundle!
         zip-profile-path!
         zip-profile!
         build-preview-keyboard-layouts!
         build-preview-skins!)

(define (build-schemas! schemas profile-out)
  (define needed
    (list->set
     (cons "yuanshu_shared.rkt"
           (map (lambda (s) (string-append (rime-schema-source-id s) ".rkt")) schemas))))
  (define entrypoints
    (sort
     (filter (lambda (p)
             (set-member? needed (path->string (file-name-from-path p))))
             (directory-list rime-source-dir #:build? #t))
     path<?))
  (for ([f entrypoints])
    (define schema-config-files
      (dynamic-require f 'schema-config-files (lambda () #f)))
    (define config-files
      (dynamic-require f 'config-files (lambda () #f)))
    (cond
      [(hash? schema-config-files)
       (for ([schema (in-list schemas)]
             #:when (equal? (path->string (file-name-from-path f))
                            (string-append (rime-schema-source-id schema) ".rkt")))
         (define files
           (hash-ref schema-config-files schema
                     (lambda ()
                       (hash-ref schema-config-files (rime-schema-config-id schema)
                                 (lambda ()
                                   (hash-ref schema-config-files (rime-schema-source-id schema)
                                             (lambda ()
                                               (error 'build-schemas!
                                                      "~a: missing generated config for ~a"
                                                      f
                                                      schema))))))))
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
                              content)])))))]
      [(or (hash? config-files) (procedure? config-files))
       (write-module-files! f profile-out 'config-files)]
      [else (void)])))

(define (keyboard-layout-module-path! layout schemas)
  (or (schema-keyboard-layout-module-path layout schemas)
      (error 'build-one-keyboard-layout!
             "No keyboard layout definition for ~a"
             layout)))

(define (write-unpacked-keyboard-layout! layout-rkt out-dir #:with-docs? [with-docs? #f])
  (make-directory* out-dir)
  (write-module-files! layout-rkt
                       out-dir
                       (if with-docs?
                           'keyboard-layout-files-with-docs
                           'keyboard-layout-files)
                       #:fresh? with-docs?))

(define (build-keyboard-layouts! layouts schemas profile-out layout-root
                                 #:render-docs? [render-docs? #t])
  (unless (null? layouts)
    (make-directory* (build-path profile-out "skins"))
    (delete-directory/files layout-root #:must-exist? #f)
    (make-directory* layout-root)
    (for ([layout layouts])
      (define layout-rkt (keyboard-layout-module-path! layout schemas))
      (define layout-out (build-path layout-root layout))
      (define cskin (build-path profile-out "skins" (string-append layout ".cskin")))
      (printf "Building keyboard layout: ~a\n" layout)
      (delete-directory/files layout-out #:must-exist? #f)
      (write-unpacked-keyboard-layout! layout-rkt layout-out #:with-docs? render-docs?)
      (delete-file* cskin)
      (make-directory* (path-only cskin))
      (parameterize ([current-directory layout-root])
        (run! zip-exe "-qr" (path->string cskin) layout)))))

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

(define (build-profile-from-hash! profile profile-name profile-out
                                  #:keyboard-layout-dir [keyboard-layout-dir #f]
                                  #:skin-dir [skin-dir #f]
                                  #:render-docs? [render-docs? #t])
  (delete-directory/files profile-out #:must-exist? #f)
  (make-directory* profile-out)

  (define schemas (resolve-schemas profile))
  (printf "Building '~a': ~a\n" profile-name (string-join schemas " "))

  (build-schemas! schemas profile-out)

  (define-values (_gen-yaml rime-yaml rime-dirs keyboard-layouts)
    (compute-assets schemas profile))

  (for ([f rime-yaml])
    (define src (build-path rime-dir f))
    (when (file-exists? src)
      (copy-file! src (build-path profile-out f))))

  (for ([d rime-dirs])
    (define src (build-path rime-dir d))
    (when (directory-exists? src)
      (copy-dir! src (build-path profile-out d))))

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
              (fprintf out "    - schema: ~a\n" (rime-schema-config-id s))))))
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
    (build-keyboard-layouts! keyboard-layouts
                             schemas
                             profile-out
                             layout-root
                             #:render-docs? render-docs?))
  (when tmp-layout-dir
    (delete-directory/files tmp-layout-dir #:must-exist? #f)))

(define (build-output! #:schemas [schemas "all"]
                       #:artifact [artifact "yuanshu"]
                       #:out-dir [out-dir output-dir]
                       #:profile-name [profile-name "rime"]
                       #:zip-path [zip-path #f]
                       #:keyboard-layout-dir [keyboard-layout-dir #f]
                       #:skin-dir [skin-dir #f]
                       #:extra-src-files [extra-src-files '()]
                       #:skip-default-custom? [skip-default-custom? #t]
                       #:render-docs? [render-docs? #t])
  (define profile
    (let ([base (hash 'schemas schemas
                      'artifact artifact
                      'skip-default-custom skip-default-custom?)])
      (if (null? extra-src-files)
          base
          (hash-set base 'extra-src-files extra-src-files))))
  (build-profile-from-hash! profile
                            profile-name
                            out-dir
                            #:keyboard-layout-dir keyboard-layout-dir
                            #:skin-dir skin-dir
                            #:render-docs? render-docs?)
  (when zip-path
    (zip-profile-path! profile-name out-dir zip-path))
  (define-values (_gen-yaml _rime-yaml _rime-dirs layouts)
    (compute-assets (resolve-schemas profile) profile))
  (values out-dir zip-path (or keyboard-layout-dir skin-dir) layouts))

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
  (define-values (built-out built-zip built-layout-dir _layouts)
    (build-output! #:schemas (hash-ref profile 'schemas '())
                   #:artifact (profile-artifact profile)
                   #:out-dir profile-out
                   #:profile-name profile-name
                   #:zip-path zip-path
                   #:keyboard-layout-dir final-layout-dir
                   #:extra-src-files (hash-ref profile 'extra-src-files '())
                   #:skip-default-custom? (hash-ref profile 'skip-default-custom #f)))
  (values built-out built-zip built-layout-dir))

(define (build-profile! profile-name)
  (define profile     (named-rime-profile profile-name))
  (define profile-out (build-path output-dir profile-name))
  (build-output! #:schemas (hash-ref profile 'schemas '())
                 #:artifact (profile-artifact profile)
                 #:out-dir profile-out
                 #:profile-name profile-name
                 #:extra-src-files (hash-ref profile 'extra-src-files '())
                 #:skip-default-custom? (hash-ref profile 'skip-default-custom #f))
  (void))

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

(define (build-preview-keyboard-layouts! #:render-docs? [render-docs? #f])
  (build-output! #:schemas "all"
                 #:artifact "yuanshu"
                 #:out-dir output-dir
                 #:profile-name "rime"
                 #:skip-default-custom? #t
                 #:render-docs? render-docs?))

(define build-preview-skins! build-preview-keyboard-layouts!)
