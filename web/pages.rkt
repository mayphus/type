#lang racket/base

(require xml
         "locale.rkt"
         "components.rkt")

(provide render-page
         render-exhibit-page)

(define (home-page req schemas layouts)
  (define locale (request-locale req))
  (page-xexpr
   locale
   "/"
     `((section ((class "rime-hero-card"))
              (div ((class "rime-hero-head"))
                   (div
                    (h1 ((class "page-title")) ,(t locale 'title)))
                   ,(language-toggle locale "/")))
     (div ((class "rime-schema-categories"))
          ,@(for/list ([category (in-list (categorized-schemas schemas))])
              (schema-category-section locale layouts category))))))

(define (exhibit-page req schemas layouts schema-ref)
  (define locale (request-locale req))
  (define requested-schema (or (schema-by-slug schemas schema-ref)
                               (schema-by-id schemas schema-ref)))
  (define schema requested-schema)
  (define platform (request-value req "platform" #f))
  (define current-path (format "/exhibits/~a" (if schema (schema-slug schema) schema-ref)))
  (page-xexpr
   locale
   current-path
   (if schema
       (let ()
         `((section ((class "rime-exhibit-overview"))
                    (div ((class "rime-exhibit-copy"))
                         (div ((class "rime-hero-head"))
                              (div
                               (a ((class "rime-back-link") (href "/")) ,(t locale 'back))
                               (h1 ((class "page-title")) ,(schema-name locale schema)))
                              ,(language-toggle locale current-path)))
                    ,@(let ([preview (schema-detail-preview locale schema layouts #:platform platform)])
                        (if preview (list preview) '()))
                    ,(schema-definition-panel schema))))
       `((section ((class "rime-hero-card"))
                  (a ((class "rime-back-link") (href "/")) ,(t locale 'back))
                  (h1 ((class "page-title")) ,(t locale 'missing)))))))

(define (render-page req schemas layouts #:route [_route 'home])
  (xexpr->string (home-page req schemas layouts)))

(define (render-exhibit-page req schemas layouts schema-id)
  (xexpr->string (exhibit-page req schemas layouts schema-id)))
