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

(define (svg-text-x svg text)
  (define match
    (regexp-match (regexp (format "<text x=\"([0-9.]+)\"[^>]*>~a</text>"
                                  (regexp-quote text)))
                  svg))
  (and match (string->number (cadr match))))

(define (first-key-width svg)
  (define match
    (regexp-match #rx"<rect x=\"[0-9.]+\" y=\"[0-9.]+\" width=\"([0-9.]+)\" height=\"[0-9.]+\""
                  svg))
  (and match (string->number (cadr match))))

(define (svg-width svg)
  (define match (regexp-match #rx"<svg[^>]+width=\"([0-9.]+)\"" svg))
  (and match (string->number (cadr match))))

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

  (test-case "dictionary variants are not schema exhibit routes"
    (define response (canonical-dispatch (req "/exhibits/flypy-ice" "rime.mayphus.org")))
    (check-equal? (response-code response) 404))

  (test-case "package variant exhibit routes are not schemas"
    (define response
      (canonical-dispatch (req "/exhibits/flypy-ice?platform=desktop" "rime.mayphus.org")))
    (check-equal? (response-code response) 404))

  (test-case "schema preview routes use hyphen slugs"
    (define response
      (canonical-dispatch (req "/schemas/double-pinyin-flypy-14/skin-preview.svg" "rime.mayphus.org")))
    (check-equal? (response-code response) 200))

  (test-case "museum home renders localized exhibit metadata"
    (define en-html (response-body (canonical-dispatch (req "/" "rime.mayphus.org"))))
    (define zh-html (response-body (canonical-dispatch (req "/?locale=zh-Hant" "rime.mayphus.org"))))
    (check-false (regexp-match? #rx"Flypy double pinyin with Rime config" en-html))
    (check-true (regexp-match? #rx"Double Pinyin" en-html))
    (check-true (regexp-match? #rx"Full Pinyin" en-html))
    (check-true (regexp-match? #rx"Zhuyin" en-html))
    (check-true (regexp-match? #rx"Jyutping" en-html))
    (check-true (regexp-match? #rx"Cangjie" en-html))
    (check-true (regexp-match? #rx"Wubi" en-html))
    (check-true (regexp-match? #rx"Luna" en-html))
    (check-equal? (length (regexp-match* #rx"href=\"/exhibits/cangjie6\"" en-html)) 1)
    (check-equal? (length (regexp-match* #rx"href=\"/exhibits/wubi86\"" en-html)) 1)
    (check-false (regexp-match? #rx"href=\"/exhibits/cangjie5\"" en-html))
    (check-false (regexp-match? #rx"href=\"/exhibits/wubi-pinyin\"" en-html))
    (check-false (regexp-match? #rx"<h2[^>]*>Cantonese</h2>" en-html))
    (check-false (regexp-match? #rx"小鶴方案，提供 Rime 設定" zh-html))
    (check-true (regexp-match? #rx"小鶴雙拼" zh-html))
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

  (test-case "standard zhuyin typing preview keeps punctuation input keys"
    (define layout-svg
      (response-body (canonical-dispatch (req "/layouts/bopomofo_standard/preview.svg" "rime.mayphus.org"))))
    (define yuanshu-svg
      (response-body (canonical-dispatch (req "/layouts/bopomofo/preview.svg" "rime.mayphus.org"))))
    (define one-x (svg-text-x layout-svg "1"))
    (define q-x (svg-text-x layout-svg "q"))
    (define a-x (svg-text-x layout-svg "a"))
    (define z-x (svg-text-x layout-svg "z"))
    (check-true (regexp-match? #rx"^<svg[^>]+Keyboard preview" layout-svg))
    (check-= (svg-width layout-svg) (svg-width yuanshu-svg) 0.01)
    (check-= (first-key-width layout-svg) (first-key-width yuanshu-svg) 0.01)
    (check-true (< one-x q-x a-x z-x))
    (check-true (regexp-match? #rx">;<" layout-svg))
    (check-true (regexp-match? #rx">,</text>" layout-svg))
    (check-true (regexp-match? #rx">/</text>" layout-svg))
    (check-true (regexp-match? #rx">ㄤ<" layout-svg)))

  (test-case "desktop detail preview includes physical keyboard controls"
    (define desktop-svg
      (response-body (canonical-dispatch (req "/schemas/double-pinyin-flypy/desktop-preview.svg" "rime.mayphus.org"))))
    (check-true (regexp-match? #rx"^<svg[^>]+Keyboard preview" desktop-svg))
    (check-true (regexp-match? #rx">Esc</text>" desktop-svg))
    (check-true (regexp-match? #rx">Tab</text>" desktop-svg))
    (check-true (regexp-match? #rx">Control</text>" desktop-svg))
    (check-true (regexp-match? #rx">Shift</text>" desktop-svg))
    (check-true (regexp-match? #rx">Option</text>" desktop-svg))
    (check-true (regexp-match? #rx">Command</text>" desktop-svg))
    (check-true (regexp-match? #rx">Fn</text>" desktop-svg))
    (check-true (regexp-match? #rx">Enter</text>" desktop-svg))
    (check-true (regexp-match? #rx">Del</text>" desktop-svg))
    (check-true (regexp-match? #rx">1</text>" desktop-svg))
    (check-true (regexp-match? #rx">=</text>" desktop-svg))
    (check-true (regexp-match? #rx">\\[</text>" desktop-svg))
    (check-true (regexp-match? #rx">\\\\</text>" desktop-svg))
    (check-true (regexp-match? #rx">;</text>" desktop-svg))
    (check-true (regexp-match? #rx"width=\"44\\.80\" height=\"44\\.80\"" desktop-svg))
    (check-false (regexp-match? #rx">123<" desktop-svg)))

  (test-case "schema preview routes preserve schema identity over shared layouts"
    (define flypy-ice-response
      (canonical-dispatch (req "/schemas/flypy-ice/preview.svg" "rime.mayphus.org")))
    (define mobile-only-svg
      (response-body (canonical-dispatch (req "/schemas/double-pinyin-flypy-14/preview.svg" "rime.mayphus.org"))))
    (define mobile-only-skin-svg
      (response-body (canonical-dispatch (req "/schemas/double-pinyin-flypy-14/skin-preview.svg" "rime.mayphus.org"))))
    (define luna-skin-svg
      (response-body (canonical-dispatch (req "/schemas/luna-pinyin/skin-preview.svg" "rime.mayphus.org"))))
    (check-equal? (response-code flypy-ice-response) 404)
    (check-true (regexp-match? #rx"^<svg[^>]+Keyboard preview" mobile-only-svg))
    (check-false (regexp-match? #rx">123<" mobile-only-svg))
    (check-true (regexp-match? #rx">123<" mobile-only-skin-svg))
    (check-true (regexp-match? #rx"^<svg[^>]+Keyboard preview" luna-skin-svg))
    (check-true (regexp-match? #rx">123<" luna-skin-svg)))
