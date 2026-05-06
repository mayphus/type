#lang racket/base

(require web-server/servlet
         web-server/servlet-env
         web-server/http
         racket/file
         racket/list
         racket/runtime-path
         json
         "web-ui.rkt"
         "build.rkt")

(provide skin-items list-static-schemas)

;; ---- Helpers ---------------------------------------------------------------

(define-runtime-path app-css-path "static/app.css")
(define-runtime-path support-svg-path "static/support.svg")

(define (valid-id? s)
  (and (string? s) (regexp-match? #rx"^[a-zA-Z0-9_-]+$" s)))

(define (skin-demo-path skin-id)
  (build-path output-dir "compiled-skins" skin-id "demo.png"))

(define (skin-preview-svgs skin-rkt)
  (with-handlers ([exn:fail? (lambda (_) (hash))])
    (dynamic-require `(file ,(path->string skin-rkt)) 'skin-preview-svgs)))

(define (skin-preview-svg skin-id [theme 'light])
  (for/or ([item (in-list skin-items)]
           #:when (equal? skin-id (car item)))
    (define preview-svgs (cadddr item))
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

;; Precompute skin data once at startup. Concrete skins are declared by
;; schema modules and materialized into temporary modules for the existing
;; Yuanshu skin compiler.
(define skin-items
  (for/list ([item (in-list (list-mobile-skin-items schema-ids))])
    (define schema-id (car item))
    (define skin-id (cadr item))
    (define skin-rkt (caddr item))
    (list skin-id
          (list schema-id)
          (dynamic-require `(file ,(path->string skin-rkt)) 'chinese-name (lambda () ""))
          (skin-preview-svgs skin-rkt))))

(define schema-items
  (for/list ([s (in-list schema-ids)])
    (define mo? (schema-module-ref s 'mobile-only? #f))
    (define deps (read-schema-deps s))
    (define mobile-skins (read-schema-mobile-skins s))
    (define zh-name (schema-module-ref s 'chinese-name (read-schema-name-from-yaml s)))
    (hash 'id s
          'name (or zh-name s)
          'deps deps
          'mobile-skins mobile-skins
          'mobile-only? mo?)))

;; ---- Handlers --------------------------------------------------------------

(define (json-error msg)
  (response/full
   400 #"Bad Request" (current-seconds) #"application/json" '()
   (list (jsexpr->bytes (hash 'error msg)))))

(define (html-response html [headers '()])
  (response/full
   200 #"OK" (current-seconds) #"text/html; charset=utf-8" headers
   (list (string->bytes/utf-8 html))))

(define (svg-response svg)
  (response/full
   200 #"OK" (current-seconds) #"image/svg+xml"
   (list (make-header #"Cache-Control" #"public, max-age=300"))
   (list (string->bytes/utf-8 svg))))

(define (handle-page req route)
  (html-response (render-page req schema-items skin-items #:route route)
                 (remember-locale-headers req)))

(define (handle-metadata req)
  (response/full
   200 #"OK" (current-seconds) #"application/json" '()
   (list (jsexpr->bytes
          (hash 'service "rime-config"
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

(define (handle-skin-demo req skin-id)
  (cond
    [(not (valid-id? skin-id))
     (json-error "Invalid skin id")]
    [else
     (define demo-path (skin-demo-path skin-id))
     (if (file-exists? demo-path)
         (response/full
          200 #"OK" (current-seconds) #"image/png"
          (list (make-header #"Cache-Control" #"public, max-age=300"))
          (list (file->bytes demo-path)))
         (response/full
          404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
         (list #"Preview image not found")))]))

(define (handle-skin-preview-svg req skin-id)
  (cond
    [(not (valid-id? skin-id))
     (json-error "Invalid skin id")]
    [else
     (define svg (skin-preview-svg skin-id))
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
  (cond
    [(not (and (list? schemas) (andmap valid-id? schemas)))
     (json-error "Invalid schema id")]
    [else
     (define profile (hash 'schemas     schemas
                           'desktop?    (hash-ref data 'desktop? #t)))
     (define final-profile
       (if (hash-ref profile 'desktop?)
           (hash-set profile 'extra-src-files '("squirrel.custom.yaml"))
           profile))

     (define tmp-dir      (make-temporary-file "rime-web-~a" 'directory))
     (define profile-name "rime-config")
     (define profile-out  (build-path tmp-dir profile-name))
     (define zip-path     (build-path tmp-dir (string-append profile-name ".zip")))

     (dynamic-wind
      void
      (lambda ()
        (build-profile-from-hash! final-profile profile-name profile-out)
        (zip-profile-path! profile-name profile-out zip-path)
        (define zip-bytes (file->bytes zip-path))
        (response/full
         200 #"OK" (current-seconds) #"application/zip"
         (list (make-header #"Content-Disposition" #"attachment; filename=\"rime-config.zip\""))
         (list zip-bytes)))
      (lambda ()
        (delete-directory/files tmp-dir)))]))

;; ---- Routing ---------------------------------------------------------------

(define-values (dispatch url)
  (dispatch-rules
   [("") (lambda (req) (handle-page req 'home))]
   [("metadata") handle-metadata]
   [("desktop") (lambda (req) (handle-page req 'desktop))]
   [("mobile") (lambda (req) (handle-page req 'mobile))]
   [("app.css") handle-app-css]
   [("support.svg") handle-support-svg]
   [("skins" (string-arg) "preview.svg") handle-skin-preview-svg]
   [("skins" (string-arg) "demo.png") handle-skin-demo]
   [("build") #:method "post" handle-build]))

(define (start)
  (define port      (let ([p (getenv "PORT")])      (if p (string->number p) 5001)))
  (define listen-ip (let ([h (getenv "LISTEN_IP")]) (or h "127.0.0.1")))
  (printf "Rime API starting on ~a:~a...\n" listen-ip port)
  (serve/servlet
   dispatch
   #:servlet-path ""
   #:servlet-regexp #rx""
   #:port port
   #:launch-browser? #f
   #:listen-ip listen-ip))

(module+ main
  (start))
