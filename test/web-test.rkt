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

(define (response-location response)
  (for/first ([header (in-list (response-headers response))]
              #:when (equal? (header-field header) #"Location"))
    (bytes->string/utf-8 (header-value header))))

(define (response-body response)
  (define out (open-output-bytes))
  ((response-output response) out)
  (bytes->string/utf-8 (get-output-bytes out)))

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

  (test-case "desktop route redirects to museum home"
    (define response (canonical-dispatch (req "/desktop" "rime.mayphus.org")))
    (check-equal? (response-code response) 302)
    (check-equal? (response-location response) "/"))

  (test-case "schema variant detail routes redirect to their base exhibit"
    (define response (canonical-dispatch (req "/exhibits/flypy_ice" "rime.mayphus.org")))
    (check-equal? (response-code response) 302)
    (check-equal? (response-location response) "/exhibits/flypy"))

  (test-case "museum catalog renders localized exhibit metadata"
    (define en-html (response-body (canonical-dispatch (req "/" "rime.mayphus.org"))))
    (define zh-html (response-body (canonical-dispatch (req "/?locale=zh-Hant" "rime.mayphus.org"))))
    (check-true (regexp-match? #rx"Flypy double pinyin with Rime config" en-html))
    (check-true (regexp-match? #rx"Double Pinyin" en-html))
    (check-true (regexp-match? #rx"Full Spelling" en-html))
    (check-true (regexp-match? #rx"Jyutping" en-html))
    (check-false (regexp-match? #rx"<h2[^>]*>Cantonese</h2>" en-html))
    (check-true (regexp-match? #rx"小鶴方案，提供 Rime 設定" zh-html))
    (check-true (regexp-match? #rx"雙拼" zh-html))
    (check-true (regexp-match? #rx"粵拼" zh-html))
    (check-false (regexp-match? #rx"Compact phonetic systems" zh-html)))

  (test-case "web keyboard layout previews are ready for page image URLs"
    (check-not-equal? keyboard-layout-items '())
    (for ([item (in-list keyboard-layout-items)])
      (define layout-id (hash-ref item 'id))
      (define names (hash-ref item 'names))
      (define preview-svgs (hash-ref item 'preview-svgs))
      (define skin-preview-svgs (hash-ref item 'skin-preview-svgs))
      (check-true (hash-has-key? names 'en))
      (check-true (hash-has-key? names 'zh-Hant))
      (for ([theme (in-list '(light dark))])
        (define svg (hash-ref preview-svgs theme #f))
        (define skin-svg (hash-ref skin-preview-svgs theme #f))
        (define expected-background
          (case theme
            [(light) "fill=\"#f6f7f9\""]
            [(dark) "fill=\"#111418\""]))
        (check-true
         (and (string? svg)
              (regexp-match? #rx"^<svg[^>]+Keyboard preview" svg))
         (format "~a preview ~a should be an SVG" layout-id theme))
        (check-true
         (and (string? svg)
              (regexp-match? (regexp-quote expected-background) svg))
         (format "~a preview ~a should use neutral diagram colors" layout-id theme))
        (check-true
         (and (string? skin-svg)
              (regexp-match? #rx"^<svg[^>]+Keyboard preview" skin-svg))
         (format "~a skin preview ~a should be an SVG" layout-id theme)))))

  (test-case "skin preview routes include non typing Yuanshu keys"
    (define skin-svg
      (response-body (canonical-dispatch (req "/skins/flypy/preview.svg" "rime.mayphus.org"))))
    (define layout-svg
      (response-body (canonical-dispatch (req "/layouts/flypy/preview.svg" "rime.mayphus.org"))))
    (check-true (regexp-match? #rx"^<svg[^>]+Keyboard preview" skin-svg))
    (check-true (regexp-match? #rx">123<" skin-svg))
    (check-true (regexp-match? #rx"fill=\"#e9edf2\"" skin-svg))
    (check-false (regexp-match? #rx">123<" layout-svg))))
