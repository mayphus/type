#lang racket/base

(require web-server/servlet
         web-server/servlet-env
         web-server/http
         racket/file
         racket/list
         racket/match
         racket/runtime-path
         racket/string
         racket/system
         net/url
         json
         style/main
         "../targets/yuanshu/skin/core/preview-svg.rkt"
         "app-style.rkt"
         "pages.rkt"
         "forms.rkt"
         "locale.rkt"
         "../build/main.rkt"
         "../catalog/methods.rkt"
         "../catalog/schemas.rkt"
         "../catalog/keymaps.rkt")

(provide keyboard-layout-items
         skin-items
         list-static-schemas
         canonical-redirect-location
         canonical-dispatch
         start)

;; ---- Helpers ---------------------------------------------------------------

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

(define preview-canvas-width 3363/8)

(define (normalize-preview-canvas preview-spec)
  (cond
    [(not (hash? preview-spec)) preview-spec]
    [else
     (define normalized
       (hash-set preview-spec 'canvas-width preview-canvas-width))
     (define dark-preview (hash-ref preview-spec 'dark #f))
     (if (hash? dark-preview)
         (hash-set normalized 'dark (normalize-preview-canvas dark-preview))
         normalized)]))

(define (keyboard-layout-preview-svgs layout-module)
  (with-handlers ([exn:fail? (lambda (_) (hash))])
    (define preview-spec
      (keyboard-layout-module-ref layout-module 'keyboard-layout-preview-spec))
    (preview-spec->svgs (normalize-preview-canvas preview-spec))))

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

(define (schema-preview-svg schema-id [theme 'light] #:skin? [skin? #f])
  (define schema
    (schema-item-by-ref schema-id))
  (define layout-id
    (and schema
         (let ([layouts (hash-ref schema 'keyboard-layouts '())])
           (and (pair? layouts) (car layouts)))))
  (and layout-id
       (if skin?
           (or (keyboard-layout-skin-preview-svg layout-id theme)
               (keyboard-layout-skin-preview-svg layout-id 'light))
           (or (keyboard-layout-preview-svg layout-id theme)
               (keyboard-layout-preview-svg layout-id 'light)))))

(define (list-static-schemas)
  (filter-map
   (lambda (f)
     (define name (path->string f))
     (and (regexp-match? #rx"\\.schema\\.yaml$" name)
          (regexp-replace #rx"\\.schema\\.yaml$" name "")))
   (directory-list rime-dir)))

(define schema-ids
  (map input-method-recipe-id input-method-recipes))

(define (lisp-atom value)
  (cond
    [(string? value) (format "~s" value)]
    [(symbol? value) (format "'~a" value)]
    [(list? value) (format "'~s" value)]
    [else (format "~s" value)]))

(define (recipe-definition-lisp recipe)
  (define id (input-method-recipe-id recipe))
  (define schema (input-method-recipe-schema recipe))
  (define schema-line
    (and (not (equal? id schema))
         (format "  #:schema ~a" (lisp-atom schema))))
  (string-join
   (filter values
           (list
            (format "(define-input-method ~a" (lisp-atom id))
            schema-line
            (format "  #:keymap ~a" (lisp-atom (input-method-recipe-keymap recipe)))
            (format "  #:keyboard ~a" (lisp-atom (input-method-recipe-keyboard recipe)))
            (format "  #:layout ~a" (lisp-atom (car (input-method-recipe-keyboard-layouts recipe))))
            (format "  #:placement ~a" (lisp-atom (input-method-recipe-placement recipe)))
            (format "  #:skeleton ~a" (lisp-atom (input-method-recipe-skeleton recipe)))
            (format "  #:projection ~a" (lisp-atom (input-method-recipe-projection recipe)))
            (format "  #:interactions ~a)" (lisp-atom (input-method-recipe-interactions recipe)))))
   "\n"))

(define standard-zhuyin-rows
  '((one two three four five six seven eight nine zero minus)
    (q w e r t y u i o p)
    (a s d f g h j k l semicolon)
    (z x c v b n m comma period slash)))

(define desktop-physical-rows
  '((esc one two three four five six seven eight nine zero minus equal backslash grave)
    ((tab 1.5) q w e r t y u i o p bracket-left bracket-right (delete 1.5))
    ((control 1.75) a s d f g h j k l semicolon quote (enter 2.25))
    ((shift-left 2.25) z x c v b n m comma period slash (shift-right 1.75) fn)
    ((option-left 1.5) (command-left 1.5) (space 7) (command-right 1.5) (option-right 1.5))))

(define standard-zhuyin-key-labels
  (hash 'one "1" 'two "2" 'three "3" 'four "4" 'five "5"
        'six "6" 'seven "7" 'eight "8" 'nine "9" 'zero "0"
        'minus "-" 'semicolon ";" 'comma "," 'period "." 'slash "/"))

(define desktop-key-labels
  (hash 'esc "Esc" 'grave "`" 'one "1" 'two "2" 'three "3" 'four "4" 'five "5"
        'six "6" 'seven "7" 'eight "8" 'nine "9" 'zero "0"
        'minus "-" 'equal "=" 'bracket-left "[" 'bracket-right "]"
        'backslash "\\" 'delete "Del" 'tab "Tab" 'semicolon ";" 'quote "'"
        'enter "Enter" 'shift-left "Shift" 'shift-right "Shift"
        'control "Control" 'control-right "Control" 'fn "Fn"
        'option-left "Option" 'option-right "Option"
        'command-left "Command" 'command-right "Command"
        'space "" 'comma "," 'period "." 'slash "/"))

(define (physical-key-label key)
  (hash-ref desktop-key-labels
            key
            (hash-ref standard-zhuyin-key-labels key (symbol->string key))))

(define (key-spec-id key-spec)
  (if (pair? key-spec) (car key-spec) key-spec))

(define (key-spec-width key-spec)
  (and (pair? key-spec) (cadr key-spec)))

(define (preview-key key-spec legend-layer)
  (define key (key-spec-id key-spec))
  (define width (key-spec-width key-spec))
  (define label (physical-key-label key))
  (define legend (and legend-layer (keymap-text legend-layer key)))
  (define key-hash
    (hash 'id (format "~aKey" key)
          'role 'input
          'label label
          'layers
          (filter values
                  (list (hash 'text label
                              'x 0.5
                              'y (if (and legend (not (string=? legend ""))) 0.24 0.5)
                              'font-size (if (> (string-length label) 3) 8 10)
                              'font-weight "500")
                        (and legend
                             (not (string=? legend ""))
                             (hash 'text legend
                                   'x 0.5
                                   'y 0.62
                                   'font-size 18
                                   'font-weight "500"))))))
  (if width
      (hash-set key-hash 'width width)
      key-hash))

(define (standard-zhuyin-key key)
  (preview-key key 'zhuyin-standard))

(define (preview-rows rows legend-layer)
  (for/list ([row (in-list rows)])
    (for/list ([key (in-list row)])
      (preview-key key legend-layer))))

(define (desktop-preview-spec legend-layer
                              #:width [width 760]
                              #:height [height 260]
                              #:rows [rows desktop-physical-rows]
                              #:row-offsets [row-offsets '(0 1/2 3/4 5/4)]
                              #:background [background "#f6f7f9"])
  (hash 'size (hash 'width width 'height height)
        'row-offsets row-offsets
        'background background
        'source 'static
        'key-shape 'square
        'visible-keys 'typing
        'rows (preview-rows rows legend-layer)))

(define standard-zhuyin-preview-rows
  (for/list ([row (in-list standard-zhuyin-rows)])
    (for/list ([key (in-list row)])
      (standard-zhuyin-key key))))

(define standard-zhuyin-preview
  (hash 'size (hash 'width 3363/8 'height 216)
        'canvas-width preview-canvas-width
        'row-offsets '(0 1/2 3/4 5/4)
        'background "#f6f7f9"
        'dark (hash 'size (hash 'width 3363/8 'height 216)
                    'canvas-width preview-canvas-width
                    'row-offsets '(0 1/2 3/4 5/4)
                    'background "#111418"
                    'source 'static
                    'key-shape 'square
                    'visible-keys 'typing
                    'rows standard-zhuyin-preview-rows)
        'source 'static
        'key-shape 'square
        'visible-keys 'typing
        'rows standard-zhuyin-preview-rows))

(define (schema-desktop-preview-svg schema-id [theme 'light])
  (define schema (schema-item-by-ref schema-id))
  (and schema
       (let ([keyboard (hash-ref schema 'keyboard #f)])
         (cond
           [(equal? keyboard 'standard-zhuyin)
            (define spec
              (desktop-preview-spec 'zhuyin-standard
                                    #:background (if (eq? theme 'dark) "#111418" "#f6f7f9")))
            (keyboard-preview-svg spec #:geometry 'physical-square)]
           [(member keyboard '(standard-26 standard-41))
            (define spec
              (desktop-preview-spec (hash-ref schema 'keymap #f)
                                    #:background (if (eq? theme 'dark) "#111418" "#f6f7f9")))
            (keyboard-preview-svg spec #:geometry 'physical-square)]
           [else #f]))))

(define standard-zhuyin-layout-item
  (hash 'id "bopomofo_standard"
        'schemas '("bopomofo-standard")
        'name "標準注音"
        'names (hash 'en "Bopomofo Standard"
                     'zh-Hant "標準注音")
        'preview-svgs (preview-spec->svgs standard-zhuyin-preview)
        'skin-preview-svgs (preview-spec->svgs standard-zhuyin-preview)))

(define legacy-hosts '("rime.mayphus.org" "rime-config.mayphus.org"))
(define canonical-host "type.mayphus.org")

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
       (member (string-downcase (host-without-port host)) legacy-hosts)
       (string-append "https://" canonical-host (url->string (request-uri req)))))

(define (canonical-redirect-response location)
  (response/full
   308 #"Permanent Redirect" (current-seconds) #"text/plain; charset=utf-8"
   (list (make-header #"Location" (string->bytes/utf-8 location))
         (make-header #"Cache-Control" #"public, max-age=86400"))
   (list #"Redirecting to type.mayphus.org")))

;; Precompute keyboard layout data once at startup. Concrete layouts are
;; declared by schema modules and materialized into temporary modules for the
;; Yuanshu .cskin compiler.
(define keyboard-layout-items
  (append
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
           'skin-preview-svgs (keyboard-layout-skin-preview-svgs layout-module)))
   (list standard-zhuyin-layout-item)))

(define skin-items
  (for/list ([layout (in-list keyboard-layout-items)])
    (list (hash-ref layout 'id)
          (hash-ref layout 'schemas)
          (hash-ref layout 'name)
          (hash-ref layout 'preview-svgs))))

(define schema-items
  (for/list ([s (in-list schema-ids)])
    (define recipe (input-method-recipe-ref s))
    (define base-schema-id (input-method-recipe-schema recipe))
    (define deps (read-schema-deps s))
    (define artifacts (read-schema-artifacts s))
    (define keyboard-layouts (read-schema-keyboard-layouts s))
    (define zh-name (schema-module-ref s 'chinese-name
                                       (read-schema-name-from-yaml base-schema-id)))
    (define description (or (read-schema-description s) ""))
    (hash 'id s
          'schema-id base-schema-id
          'keymap (input-method-recipe-keymap recipe)
          'keyboard (input-method-recipe-keyboard recipe)
          'layout (car (input-method-recipe-keyboard-layouts recipe))
          'placement (input-method-recipe-placement recipe)
          'definition-lisp (recipe-definition-lisp recipe)
          'slug (schema-slug s)
          'name (or zh-name s)
          'names (or (input-method-recipe-names recipe)
                     (schema-display-names base-schema-id)
                     (hash 'en (or zh-name s)
                           'zh-Hant (or zh-name s)))
          'description description
          'descriptions (or (input-method-recipe-descriptions recipe)
                            (schema-display-descriptions base-schema-id)
                            (hash 'en description
                                  'zh-Hant description))
          'input-method? #t
          'deps deps
          'artifacts artifacts
          'keyboard-layouts keyboard-layouts)))

(define (schema-item-by-ref ref)
  (for/first ([item (in-list schema-items)]
              #:when (or (equal? ref (hash-ref item 'id))
                         (equal? ref (hash-ref item 'slug))))
    item))

(define (schema-item-by-id id)
  (for/first ([item (in-list schema-items)]
              #:when (equal? id (hash-ref item 'id)))
    item))

(define (schema-public-ref schema)
  (hash-ref schema 'slug (hash-ref schema 'id)))

(define (request-query-suffix req)
  (define uri (url->string (request-uri req)))
  (match (regexp-match #rx"\\?.*$" uri)
    [(list query) query]
    [_ ""]))

(define (exhibit-location schema req)
  (string-append "/exhibits/"
                 (schema-public-ref schema)
                 (request-query-suffix req)))

(define (schema-asset-location schema filename)
  (format "/schemas/~a/~a" (schema-public-ref schema) filename))

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
    [else
     (define schema (schema-item-by-ref schema-id))
     (cond
       [(not schema)
        (response/full
         404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
         (list #"Exhibit not found"))]
       [(and schema (not (equal? schema-id (schema-public-ref schema))))
        (redirect-response (exhibit-location schema req) 301)]
       [else
        (html-response (render-exhibit-page req schema-items keyboard-layout-items schema-id)
                       (remember-locale-headers req))])]))

(define (handle-metadata req)
  (response/full
   200 #"OK" (current-seconds) #"application/json" '()
   (list (jsexpr->bytes
          (hash 'service "input-foundry"
                'status "ok")))))

(define (handle-dev-reload-token req)
  (define token (getenv "INPUT_FOUNDRY_DEV_RELOAD_TOKEN"))
  (if token
      (response/full
       200 #"OK" (current-seconds) #"text/plain; charset=utf-8"
       (list (make-header #"Cache-Control" #"no-store"))
       (list (string->bytes/utf-8 token)))
      (response/full
       404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
       (list #"Dev reload is disabled"))))

(define (handle-app-css req)
  (response/full
   200 #"OK" (current-seconds) #"text/css; charset=utf-8"
   (list (make-header #"Cache-Control" #"no-store"))
   (list (string->bytes/utf-8 (string-append css-text "\n" app-css-text)))))

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

(define (handle-schema-preview-svg req schema-id [theme 'light])
  (cond
    [(not (valid-id? schema-id))
     (json-error "Invalid schema id")]
    [else
     (define schema (schema-item-by-ref schema-id))
     (cond
       [(and schema (not (equal? schema-id (schema-public-ref schema))))
        (redirect-response
         (schema-asset-location schema
                                (if (eq? theme 'dark)
                                    "preview-dark.svg"
                                    "preview.svg"))
         301)]
       [else
        (define svg (schema-preview-svg schema-id theme))
        (if svg
            (svg-response svg)
            (response/full
             404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
             (list #"Preview SVG not found")))])]))

(define (handle-schema-desktop-preview-svg req schema-id [theme 'light])
  (cond
    [(not (valid-id? schema-id))
     (json-error "Invalid schema id")]
    [else
     (define schema (schema-item-by-ref schema-id))
     (cond
       [(and schema (not (equal? schema-id (schema-public-ref schema))))
        (redirect-response
         (schema-asset-location schema
                                (if (eq? theme 'dark)
                                    "desktop-preview-dark.svg"
                                    "desktop-preview.svg"))
         301)]
       [else
        (define svg (schema-desktop-preview-svg schema-id theme))
        (if svg
            (svg-response svg)
            (response/full
             404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
             (list #"Preview SVG not found")))])]))

(define (handle-schema-skin-preview-svg req schema-id [theme 'light])
  (cond
    [(not (valid-id? schema-id))
     (json-error "Invalid schema id")]
    [else
     (define schema (schema-item-by-ref schema-id))
     (cond
       [(and schema (not (equal? schema-id (schema-public-ref schema))))
        (redirect-response
         (schema-asset-location schema
                                (if (eq? theme 'dark)
                                    "skin-preview-dark.svg"
                                    "skin-preview.svg"))
         301)]
       [else
        (define svg (schema-preview-svg schema-id theme #:skin? #t))
        (if svg
            (svg-response svg)
            (response/full
             404 #"Not Found" (current-seconds) #"text/plain; charset=utf-8" '()
             (list #"Preview SVG not found")))])]))

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
   [("__dev" "reload-token") handle-dev-reload-token]
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
   [("schemas" (string-arg) "preview.svg") handle-schema-preview-svg]
   [("schemas" (string-arg) "preview-dark.svg")
    (lambda (req schema-id)
      (handle-schema-preview-svg req schema-id 'dark))]
   [("schemas" (string-arg) "desktop-preview.svg") handle-schema-desktop-preview-svg]
   [("schemas" (string-arg) "desktop-preview-dark.svg")
    (lambda (req schema-id)
      (handle-schema-desktop-preview-svg req schema-id 'dark))]
   [("schemas" (string-arg) "skin-preview.svg") handle-schema-skin-preview-svg]
   [("schemas" (string-arg) "skin-preview-dark.svg")
    (lambda (req schema-id)
      (handle-schema-skin-preview-svg req schema-id 'dark))]
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
