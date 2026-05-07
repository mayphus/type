#lang racket/base

(require rackunit
         net/url
         racket/promise
         web-server/http
         "../web.rkt")

(define (req path host)
  (request #"GET"
           (string->url path)
           (list (header #"Host" (string->bytes/utf-8 host)))
           (delay '())
           #f
           "127.0.0.1"
           5001
           "127.0.0.1"))

(module+ test
  (test-case "legacy host redirects to canonical rime domain"
    (check-equal? (canonical-redirect-location
                   (req "/desktop?locale=zh-Hant" "rime-config.mayphus.org"))
                  "https://rime.mayphus.org/desktop?locale=zh-Hant")
    (check-equal? (canonical-redirect-location
                   (req "/?locale=en" "rime-config.mayphus.org:443"))
                  "https://rime.mayphus.org/?locale=en")
    (check-false (canonical-redirect-location
                  (req "/" "rime.mayphus.org"))))

  (test-case "web skin previews are ready for page image URLs"
    (check-not-equal? skin-items '())
    (for ([item (in-list skin-items)])
      (define skin-id (car item))
      (define preview-svgs (cadddr item))
      (for ([theme (in-list '(light dark))])
        (define svg (hash-ref preview-svgs theme #f))
        (check-true
         (and (string? svg)
              (regexp-match? #rx"^<svg[^>]+Keyboard preview" svg))
         (format "~a preview ~a should be an SVG" skin-id theme))))))
