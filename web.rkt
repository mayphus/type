#lang racket/base

(require web-server/servlet
         web-server/servlet-env
         web-server/http
         racket/file
         racket/list
         racket/runtime-path
         racket/string
         racket/system
         net/url
         json
         "preview/svg.rkt"
         "web/pages.rkt"
         "web/forms.rkt"
         "web/locale.rkt"
         "build.rkt"
         "schema/registry.rkt")

(provide keyboard-layout-items
         skin-items
         list-static-schemas
         canonical-redirect-location
         canonical-dispatch)

;; ---- Helpers ---------------------------------------------------------------

(define-runtime-path app-css-path "static/app.css")
(define-runtime-path support-svg-path "static/support-8f6d2b.svg")

(define (valid-id? s)
  (and (string? s) (regexp-match? #rx"^[a-zA-Z0-9_-]+$" s)))

(define unzip-exe (find-executable-path "unzip"))

(define (keyboard-layout-demo-bytes layout-id)
  (define cskin (build-path output-dir "skins" (string-append layout-id ".cskin")))
  (and unzip-exe
       (file-exists? cskin)
       (let ([out (open-output-bytes)]
             [err (open-output-string)])
         (and
          (parameterize ([current-output-port out]
                         [current-error-port err])
            (system* unzip-exe
                     "-p"
                     (path->string cskin)
                     (string-append layout-id "/demo.png")))
          (get-output-bytes out)))))

(define (keyboard-layout-preview-svgs layout-module)
  (with-handlers ([exn:fail? (lambda (_) (hash))])
    (keyboard-layout-module-ref layout-module 'keyboard-layout-preview-svgs)))

(define (keyboard-layout-skin-preview-svgs layout-module)
  (with-handlers ([exn:fail? (lambda (_) (hash))])
    (define preview-spec
      (keyboard-layout-module-ref layout-module 'keyboard-layout-preview-spec))
    (define (preview-for-theme theme)
      (cond
        [(not (hash? preview-spec)) #f]
        [(eq? theme 'dark) (hash-ref preview-spec 'dark #f)]
        [else (hash-remove preview-spec 'dark)]))
    (define (render theme)
      (define preview (preview-for-theme theme))
      (and (hash? preview)
           (keyboard-skin-preview-svg preview)))
    (for/hash ([theme (in-list '(light dark))]
               #:do [(define svg (render theme))]
               #:when svg)
      (values theme svg))))

(define (keyboard-layout-preview-svg layout-id [theme 'light])
  (for/or ([item (in-list keyboard-layout-items)]
           #:when (equal? layout-id (hash-ref item 'id)))
    (define preview-svgs (hash-ref item 'preview-svgs))
    (hash-ref preview-svgs theme #f)))

(define (keyboard-layout-skin-preview-svg layout-id [theme 'light])
  (for/or ([item (in-list keyboard-layout-items)]
           #:when (equal? layout-id (hash-ref item 'id)))
    (define preview-svgs (hash-ref item 'skin-preview-svgs))
    (hash-ref preview-svgs theme #f)))

(define (list-static-schemas)
  (filter-map
   (lambda (f)
     (define name (path->string f))
     (and (regexp-match? #rx"\\.schema\\.yaml$" name)
          (regexp-replace #rx"\\.schema\\.yaml$" name "")))
   (directory-list rime-dir)))

(define schema-ids
  (remove-duplicates (append generated-config-ids (list-static-schemas))))

(define legacy-host "rime-config.mayphus.org")
(define canonical-host "rime.mayphus.org")

(define (request-host req)
  (for/first ([header (in-list (request-headers/raw req))]
              #:when (string-ci=? (bytes->string/utf-8 (header-field header))
                                  "host"))
    (bytes->string/utf-8 (header-value header))))

(define (host-without-port host)
  (car (string-split host ":")))

(define (canonical-redirect-location req)
  (define host (request-host req))
  (and host
       (string-ci=? (host-without-port host) legacy-host)
       (string-append "https://" canonical-host (url->string (request-uri req)))))

(define (canonical-redirect-response location)
  (response/full
   308 #"Permanent Redirect" (current-seconds) #"text/plain; charset=utf-8"
   (list (make-header #"Location" (string->bytes/utf-8 location))
         (make-header #"Cache-Control" #"public, max-age=86400"))
   (list #"Redirecting to rime.mayphus.org")))

;; Precompute keyboard layout data once at startup. Concrete layouts are
;; declared by schema modules and materialized into temporary modules for the
;; Yuanshu .cskin compiler.
(define keyboard-layout-items
  (for/list ([item (in-list (list-keyboard-layout-items schema-ids))])
    (define schema-id (car item))
    (define layout-id (cadr item))
    (define layout-module (caddr item))
    (hash 'id layout-id
          'schemas (list schema-id)
          'name (keyboard-layout-module-ref layout-module 'chinese-name (lambda () ""))
          'names (hash 'en (keyboard-layout-module-ref layout-module 'english-name (lambda () ""))
                       'zh-Hant (keyboard-layout-module-ref layout-module 'chinese-name (lambda () "")))
          'preview-svgs (keyboard-layout-preview-svgs layout-module)
          'skin-preview-svgs (keyboard-layout-skin-preview-svgs layout-module))))

(define skin-items
  (for/list ([layout (in-list keyboard-layout-items)])
    (list (hash-ref layout 'id)
          (hash-ref layout 'schemas)
          (hash-ref layout 'name)
          (hash-ref layout 'preview-svgs))))

(define schema-items
  (for/list ([s (in-list schema-ids)])
    (define deps (read-schema-deps s))
    (define artifacts (read-schema-artifacts s))
    (define keyboard-layouts (read-schema-keyboard-layouts s))
    (define zh-name (schema-module-ref s 'chinese-name (read-schema-name-from-yaml s)))
    (define description (or (read-schema-description s) ""))
    (hash 'id s
          'name (or zh-name s)
          'names (or (schema-display-names s)
                     (hash 'en (or zh-name s)
                           'zh-Hant (or zh-name s)))
          'description description
          'descriptions (or (schema-display-descriptions s)
                            (hash 'en description
                                  'zh-Hant description))
          'deps deps
          'artifacts artifacts
          'keyboard-layouts keyboard-layouts)))

;; ---- Handlers --------------------------------------------------------------

(define (json-error msg)
  (response/full
   400 #"Bad Request" (current-seconds) #"application/json" '()
   (list (jsexpr->bytes (hash 'error msg)))))

(define (html-response html [headers '()])
  (response/full
   200 #"OK" (current-seconds) #"text/html; charset=utf-8" headers
   (list (string->bytes/utf-8 html))))

(define (redirect-response location [code 302])
  (response/full
   code #"Found" (current-seconds) #"text/plain; charset=utf-8"
   (list (make-header #"Location" (string->bytes/utf-8 location)))
   (list #"Redirecting")))

(define (svg-response svg)
  (response/full
   200 #"OK" (current-seconds) #"image/svg+xml"
   (list (make-header #"Cache-Control" #"no-store"))
   (list (string->bytes/utf-8 svg))))

(define (handle-page req)
  (html-response (render-page req schema-items keyboard-layout-items)
                 (remember-locale-headers req)))

(define (handle-exhibit req schema-id)
  (cond
    [(not (valid-id? schema-id))
     (json-error "Invalid schema id")]
    [(not (equal? schema-id (schema-source-id schema-id)))
     (redirect-response (format "/exhibits/~a" (schema-source-id schema-id)))]
    [else
     (html-response (render-exhibit-page req schema-items keyboard-layout-items schema-id)
                    (remember-locale-headers req))]))

(define (handle-metadata req)
  (response/full
   200 #"OK" (current-seconds) #"application/json" '()
   (list (jsexpr->bytes
          (hash 'service "input-foundry"
                'status "ok")))))

(define (handle-app-css req)
  (if (file-exists? app-css-path)
      (response/full
       200 #"OK" (current-seconds) #"text/css; charset=utf-8"
       (list (make-header #"Cache-Control" #"no-store"))
       (list (file->bytes app-css-path)))
      (response/full
       404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
       (list #"CSS not found"))))

(define (handle-support-svg req)
  (if (file-exists? support-svg-path)
      (response/full
       200 #"OK" (current-seconds) #"image/svg+xml"
       (list (make-header #"Cache-Control" #"public, max-age=86400"))
       (list (file->bytes support-svg-path)))
      (response/full
       404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
       (list #"Support QR not found"))))

(define (handle-keyboard-layout-demo req layout-id)
  (cond
    [(not (valid-id? layout-id))
     (json-error "Invalid keyboard layout id")]
    [else
     (define demo-bytes (keyboard-layout-demo-bytes layout-id))
     (if demo-bytes
         (response/full
          200 #"OK" (current-seconds) #"image/png"
          (list (make-header #"Cache-Control" #"public, max-age=300"))
          (list demo-bytes))
         (response/full
          404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
         (list #"Preview image not found")))]))

(define (handle-keyboard-layout-preview-svg req layout-id [theme 'light])
  (cond
    [(not (valid-id? layout-id))
     (json-error "Invalid keyboard layout id")]
    [else
     (define svg (or (keyboard-layout-preview-svg layout-id theme)
                     (keyboard-layout-preview-svg layout-id 'light)))
     (if svg
         (svg-response svg)
         (response/full
          404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
          (list #"Preview SVG not found")))]))

(define (handle-keyboard-layout-skin-preview-svg req layout-id [theme 'light])
  (cond
    [(not (valid-id? layout-id))
     (json-error "Invalid keyboard layout id")]
    [else
     (define svg (or (keyboard-layout-skin-preview-svg layout-id theme)
                     (keyboard-layout-skin-preview-svg layout-id 'light)))
     (if svg
         (svg-response svg)
         (response/full
          404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
          (list #"Preview SVG not found")))]))

(define (handle-build req)
  (define body-bytes (request-post-data/raw req))
  (define data
    (cond
      [(form-request? req) (form-profile req)]
      [body-bytes (bytes->jsexpr body-bytes)]
      [else (hash)]))
  (define schemas     (hash-ref data 'schemas '()))
  (define artifact    (profile-artifact data))
  (cond
    [(not (and (list? schemas) (andmap valid-id? schemas)))
     (json-error "Invalid schema id")]
    [else
     (define profile (hash 'schemas     schemas
                           'artifact    artifact))
     (define final-profile
       (if (equal? artifact "rime")
           (hash-set profile 'extra-src-files '("squirrel.custom.yaml"))
           profile))

     (define tmp-dir      (make-temporary-file "rime-web-~a" 'directory))
     (define profile-name "input-foundry")
     (define profile-out  (build-path tmp-dir profile-name))
     (define zip-path     (build-path tmp-dir (string-append profile-name ".zip")))

     (dynamic-wind
      void
      (lambda ()
        (build-output! #:schemas schemas
                       #:artifact artifact
                       #:out-dir profile-out
                       #:profile-name profile-name
                       #:zip-path zip-path
                       #:extra-src-files (hash-ref final-profile 'extra-src-files '())
                       #:skip-default-custom? #f)
        (define zip-bytes (file->bytes zip-path))
        (response/full
         200 #"OK" (current-seconds) #"application/zip"
         (list (make-header #"Content-Disposition" #"attachment; filename=\"input-foundry.zip\""))
         (list zip-bytes)))
      (lambda ()
        (delete-directory/files tmp-dir)))]))

;; ---- Routing ---------------------------------------------------------------

(define-values (dispatch url)
  (dispatch-rules
   [("") handle-page]
   [("metadata") handle-metadata]
   [("desktop") (lambda (req) (redirect-response "/"))]
   [("exhibits" (string-arg)) handle-exhibit]
   [("app.css") handle-app-css]
   [("support-8f6d2b.svg") handle-support-svg]
   [("layouts" (string-arg) "preview.svg") handle-keyboard-layout-preview-svg]
   [("layouts" (string-arg) "preview-dark.svg")
    (lambda (req layout-id)
      (handle-keyboard-layout-preview-svg req layout-id 'dark))]
   [("layouts" (string-arg) "demo.png") handle-keyboard-layout-demo]
   [("skins" (string-arg) "preview.svg") handle-keyboard-layout-skin-preview-svg]
   [("skins" (string-arg) "preview-dark.svg")
    (lambda (req layout-id)
      (handle-keyboard-layout-skin-preview-svg req layout-id 'dark))]
   [("skins" (string-arg) "demo.png") handle-keyboard-layout-demo]
   [("build") #:method "post" handle-build]))

(define (canonical-dispatch req)
  (define location (canonical-redirect-location req))
  (if location
      (canonical-redirect-response location)
      (dispatch req)))

(define (start)
  (define port      (let ([p (getenv "PORT")])      (if p (string->number p) 5001)))
  (define listen-ip (let ([h (getenv "LISTEN_IP")]) (or h "127.0.0.1")))
  (printf "Rime API starting on ~a:~a...\n" listen-ip port)
  (serve/servlet
   canonical-dispatch
   #:servlet-path ""
   #:servlet-regexp #rx""
   #:port port
   #:launch-browser? #f
   #:listen-ip listen-ip))

(module+ main
  (start))
