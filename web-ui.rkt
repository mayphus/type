#lang racket/base

(require racket/list
         racket/match
         racket/string
         net/url
         web-server/http
         xml
         "schema/registry.rkt")

(provide render-page
         render-exhibit-page
         remember-locale-headers
         form-profile
         form-request?)

(define app-css-href "/app.css?v=20260508-museum")

(define copy
  (hash
   'en
   (hash
    'title "Chinese Input Method Museum"
    'landing-copy "Browse input methods by family. Open an exhibit for layouts, dependencies, and downloads."
    'back "Home"
    'layouts "Keyboard layouts"
    'dependencies "Dependencies"
    'no-dependencies "No extra schema dependencies."
    'rime "Rime"
    'yuanshu "Yuanshu"
    'download-rime "Download Rime package"
    'download-yuanshu "Download Yuanshu package"
    'missing "Exhibit not found."
    'support "Support"
    'footer-credit "Powered by Racket on pb62"
    'language "繁")
   'zh-Hant
   (hash
    'title "中文輸入博物館"
    'landing-copy "按輸入法家族瀏覽。進入展品查看鍵盤佈局、依賴與下載。"
    'back "首頁"
    'layouts "鍵盤佈局"
    'dependencies "依賴方案"
    'no-dependencies "沒有額外方案依賴。"
    'rime "Rime"
    'yuanshu "元書"
    'download-rime "下載 Rime 套件"
    'download-yuanshu "下載元書套件"
    'missing "找不到這個展品。"
    'support "支持"
    'footer-credit "Powered by Racket on pb62"
    'language "EN")))

(define locale-cookie-name "rime-locale")

(define (t locale key)
  (hash-ref (hash-ref copy locale) key))

(define (localized-value value locale [default ""])
  (define (string-or-default maybe-value)
    (if (and (string? maybe-value)
             (not (string=? maybe-value "")))
        maybe-value
        default))
  (cond
    [(hash? value)
     (string-or-default
      (or (hash-ref value locale #f)
          (hash-ref value 'en #f)
          (hash-ref value 'zh-Hant #f)))]
    [(string? value) (string-or-default value)]
    [else default]))

(define (next-locale locale)
  (if (eq? locale 'zh-Hant) 'en 'zh-Hant))

(define (locale-param value)
  (if (equal? value "zh-Hant") 'zh-Hant 'en))

(define (locale-value? value)
  (or (equal? value "en")
      (equal? value "zh-Hant")))

(define (binding-value binding)
  (and (binding:form? binding)
       (bytes->string/utf-8 (binding:form-value binding))))

(define (request-values req key)
  (append
   (for/list ([binding (in-list (request-bindings/raw req))]
              #:when (equal? (bytes->string/utf-8 (binding-id binding)) key)
              #:do [(define value (binding-value binding))]
              #:when value)
     value)
   (for/list ([query-param (in-list (url-query (request-uri req)))]
              #:when (equal? (symbol->string (car query-param)) key)
              #:do [(define value (cdr query-param))]
              #:when value)
     value)))

(define (request-value req key [default #f])
  (match (request-values req key)
    [(list value _ ...) value]
    [_ default]))

(define (request-cookie-value req name)
  (for/first ([cookie (in-list (request-cookies req))]
              #:when (equal? (client-cookie-name cookie) name))
    (client-cookie-value cookie)))

(define (request-locale req)
  (locale-param
   (or (request-value req "locale" #f)
       (request-cookie-value req locale-cookie-name)
       "en")))

(define (remember-locale-headers req)
  (define locale (request-value req "locale" #f))
  (if (locale-value? locale)
      (list (cookie->header
             (make-cookie locale-cookie-name locale
                          #:path "/"
                          #:max-age (* 60 60 24 365))))
      '()))

(define (form-request? req)
  (define headers (request-headers/raw req))
  (for/or ([header (in-list headers)])
    (and (string-ci=? (bytes->string/utf-8 (header-field header)) "content-type")
         (regexp-match? #rx#"application/x-www-form-urlencoded"
                        (header-value header)))))

(define (valid-artifact value)
  (cond
    [(or (equal? value "rime") (equal? value "yuanshu")) value]
    [(equal? value "true") "rime"]
    [(equal? value "false") "yuanshu"]
    [else #f]))

(define (form-profile req)
  (define schemas (request-values req "schemas"))
  (define artifact
    (or (valid-artifact (request-value req "artifact" #f))
        (valid-artifact (request-value req "desktop?" #f))
        "rime"))
  (hash 'schemas schemas
        'artifact artifact))

(define (schema-id schema)
  (hash-ref schema 'id))

(define (schema-name locale schema)
  (localized-value (hash-ref schema 'names
                             (hash-ref schema 'name (schema-id schema)))
                   locale
                   (schema-id schema)))

(define (schema-description locale schema)
  (localized-value (hash-ref schema 'descriptions
                             (hash-ref schema 'description ""))
                   locale))

(define (schema-deps schema)
  (hash-ref schema 'deps '()))

(define (schema-artifacts schema)
  (hash-ref schema 'artifacts '()))

(define (schema-keyboard-layouts schema)
  (hash-ref schema 'keyboard-layouts '()))

(define (schema-by-id schemas id)
  (for/first ([schema (in-list schemas)]
              #:when (equal? id (schema-id schema)))
    schema))

(define (layout-id layout)
  (hash-ref layout 'id))

(define (layout-name locale layout)
  (localized-value (hash-ref layout 'names
                             (hash-ref layout 'name (layout-id layout)))
                   locale
                   (layout-id layout)))

(define (layout-by-id layouts id)
  (for/first ([layout (in-list layouts)]
              #:when (equal? id (layout-id layout)))
    layout))

(define (schema-layout-items schema layouts)
  (filter values
          (for/list ([layout-id (in-list (schema-keyboard-layouts schema))])
            (layout-by-id layouts layout-id))))

(define (cataloged-schemas schemas)
  (filter-map
   (lambda (catalog-id)
     (define items
       (filter (lambda (schema)
                 (equal? (schema-id->catalog-id (schema-id schema)) catalog-id))
               schemas))
     (and (pair? items) (cons catalog-id items)))
   schema-catalog-order))

(define (classes . parts)
  (string-join (filter (lambda (part) part) parts) " "))

(define (attrs . pairs)
  (filter values pairs))

(define (language-toggle locale current-path)
  `(a ((class "rime-language-toggle rime-footer-language")
       (href ,(format "~a?locale=~a"
                      current-path
                      (symbol->string (next-locale locale)))))
      ,(t locale 'language)))

(define (layout-preview locale layout)
  `(div ((class "rime-layout-preview keyboard-preview keyboard-preview-svg-wrap"))
        (picture
         (source ((media "(prefers-color-scheme: dark)")
                  (srcset ,(format "/layouts/~a/preview-dark.svg" (layout-id layout)))))
         (img ((class "keyboard-preview-svg")
               (loading "lazy")
               (src ,(format "/layouts/~a/preview.svg" (layout-id layout)))
               (alt ,(layout-name locale layout)))))))

(define (schema-card locale schema layouts)
  (define preview-layouts (schema-layout-items schema layouts))
  `(a ((class "rime-exhibit-card")
       (href ,(format "/exhibits/~a" (schema-id schema))))
      (div ((class "rime-option-head"))
           (div ((class "rime-option-copy"))
                (div ((class "rime-option-title-row"))
                     (span ((class "rime-option-title")) ,(schema-name locale schema)))))
      (p ((class "rime-card-description")) ,(schema-description locale schema))
      ,@(if (pair? preview-layouts)
            `((div ((class "rime-schema-previews"))
                   ,@(for/list ([layout (in-list preview-layouts)])
                       (layout-preview locale layout))))
            '())))

(define (catalog-section locale layouts catalog)
  (define catalog-id (car catalog))
  (define schemas (cdr catalog))
  `(section ((class "rime-schema-catalog"))
            (div ((class "rime-catalog-heading"))
                 (h2 ((class "rime-schema-catalog-title"))
                     ,(schema-catalog-label catalog-id locale))
                 (p ((class "rime-section-copy"))
                    ,(schema-catalog-summary catalog-id locale)))
            (div ((class "rime-option-grid"))
                 ,@(for/list ([schema (in-list schemas)])
                     (schema-card locale schema layouts)))))

(define (footer locale current-path)
  `(footer ((class "rime-footer"))
           (span ((class "rime-footer-credit")) ,(t locale 'footer-credit))
           (div ((class "rime-footer-support"))
                (span ((class "rime-footer-support-label")) ,(t locale 'support))
                (img ((class "rime-footer-support-image")
                      (src "/support-8f6d2b.svg")
                      (alt ,(t locale 'support)))))
           ,(language-toggle locale current-path)))

(define (page-xexpr locale current-path body)
  `(html ((lang ,(if (eq? locale 'zh-Hant) "zh-Hant" "en")))
         (head
          (meta ((charset "utf-8")))
          (meta ((name "viewport") (content "width=device-width, initial-scale=1")))
          (title ,(t locale 'title))
          (link ((rel "stylesheet") (href ,app-css-href))))
         (body
          (main ((id "app"))
                (div ((class "rime-museum-shell"))
                     ,@body
                     ,(footer locale current-path))))))

(define (catalog-page req schemas layouts)
  (define locale (request-locale req))
  (page-xexpr
   locale
   "/"
   `((section ((class "rime-hero-card"))
              (div ((class "rime-hero-head"))
                   (div
                    (h1 ((class "page-title")) ,(t locale 'title))
                    (p ((class "rime-section-copy rime-hero-copy"))
                       ,(t locale 'landing-copy)))))
     (div ((class "rime-schema-catalogs"))
          ,@(for/list ([catalog (in-list (cataloged-schemas schemas))])
              (catalog-section locale layouts catalog))))))

(define (dependency-list locale deps)
  (if (null? deps)
      `(p ((class "rime-empty-state")) ,(t locale 'no-dependencies))
      `(ul ((class "rime-dependency-list"))
           ,@(for/list ([dep (in-list deps)])
               `(li (code ,dep))))))

(define (artifact-form locale schema artifact)
  `(form ((class "rime-artifact-form")
          (method "post")
          (action "/build"))
         (input ((type "hidden") (name "schemas") (value ,(schema-id schema))))
         (input ((type "hidden") (name "artifact") (value ,artifact)))
         (button ((class ,(classes "rime-build-button"
                                   (and (equal? artifact "yuanshu")
                                        "rime-build-button-secondary")))
                  (type "submit"))
                 ,(if (equal? artifact "yuanshu")
                      (t locale 'download-yuanshu)
                      (t locale 'download-rime)))))

(define (layout-detail-card locale layout)
  `(article ((class "rime-layout-card"))
            (div ((class "rime-option-title-row"))
                 (h3 ((class "rime-layout-title")) ,(layout-name locale layout))
                 (span ((class "rime-option-id")) ,(layout-id layout)))
            ,(layout-preview locale layout)))

(define (exhibit-page req schemas layouts schema-id*)
  (define locale (request-locale req))
  (define schema (schema-by-id schemas schema-id*))
  (define current-path (format "/exhibits/~a" schema-id*))
  (page-xexpr
   locale
   current-path
   (if schema
       (let* ([catalog-id (schema-id->catalog-id (schema-id schema))]
              [schema-layouts (schema-layout-items schema layouts)]
              [artifacts (schema-artifacts schema)])
         `((section ((class "rime-hero-card rime-exhibit-hero"))
                    (div ((class "rime-hero-head"))
                         (div
                          (a ((class "rime-back-link") (href "/")) ,(t locale 'back))
                          (h1 ((class "page-title")) ,(schema-name locale schema))
                          (p ((class "rime-section-copy rime-hero-copy"))
                             ,(schema-description locale schema))))
                    (div ((class "rime-exhibit-meta"))
                         (span ((class "rime-family-label")) ,(schema-catalog-label catalog-id locale))
                         (span ((class "rime-option-id")) ,(schema-id schema))))
           (section ((class "rime-exhibit-actions"))
                    ,@(for/list ([artifact (in-list artifacts)])
                        (artifact-form locale schema artifact)))
           (section ((class "rime-section rime-exhibit-section"))
                    (h2 ((class "rime-section-title")) ,(t locale 'layouts))
                    (div ((class "rime-layout-grid"))
                         ,@(for/list ([layout (in-list schema-layouts)])
                             (layout-detail-card locale layout))))
           (section ((class "rime-section rime-exhibit-section"))
                    (h2 ((class "rime-section-title")) ,(t locale 'dependencies))
                    ,(dependency-list locale (schema-deps schema)))))
       `((section ((class "rime-hero-card"))
                  (a ((class "rime-back-link") (href "/")) ,(t locale 'back))
                  (h1 ((class "page-title")) ,(t locale 'missing)))))))

(define (render-page req schemas layouts #:route [_route 'home])
  (xexpr->string (catalog-page req schemas layouts)))

(define (render-exhibit-page req schemas layouts schema-id)
  (xexpr->string (exhibit-page req schemas layouts schema-id)))
