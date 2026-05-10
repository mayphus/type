#lang racket/base

(require rackunit
         net/url
         racket/promise
         web-server/http
         "../web/pages.rkt"
         "../web/forms.rkt")

(define schemas
  (list (hash 'id "flypy"
              'name "小鶴"
              'names (hash 'en "Flypy" 'zh-Hant "小鶴")
              'description "Flypy double pinyin exhibit."
              'descriptions (hash 'en "Flypy double pinyin exhibit."
                                  'zh-Hant "小鶴展品。")
              'deps '("cangjie6")
              'artifacts '("rime" "yuanshu")
              'keyboard-layouts '("flypy"))
        (hash 'id "flypy_14"
              'name "小鶴十四鍵"
              'names (hash 'en "Flypy 14-Key" 'zh-Hant "小鶴十四鍵")
              'description "A compact Yuanshu-only 14-key exhibit."
              'descriptions (hash 'en "A compact Yuanshu-only 14-key exhibit."
                                  'zh-Hant "緊湊的元書十四鍵展品。")
              'deps '("flypy")
              'artifacts '("yuanshu")
              'keyboard-layouts '("flypy_14"))
        (hash 'id "flypy_ice"
              'name "小鶴霧凇"
              'names (hash 'en "Flypy Ice" 'zh-Hant "小鶴霧凇")
              'description "Flypy with rime-ice dictionaries."
              'descriptions (hash 'en "Flypy with rime-ice dictionaries."
                                  'zh-Hant "使用霧凇詞庫的小鶴。")
              'deps '("cangjie6")
              'artifacts '("rime" "yuanshu")
              'keyboard-layouts '("flypy"))))

(define layouts
  (list (hash 'id "flypy"
              'schemas '("flypy")
              'name "小鶴"
              'names (hash 'en "Flypy" 'zh-Hant "小鶴")
              'preview-svgs (hash 'light "<svg/>")
              'skin-preview-svgs (hash 'light "<svg/>"))
        (hash 'id "flypy_14"
              'schemas '("flypy_14")
              'name "小鶴十四鍵"
              'names (hash 'en "Flypy 14-Key" 'zh-Hant "小鶴十四鍵")
              'preview-svgs (hash 'light "<svg/>")
              'skin-preview-svgs (hash 'light "<svg/>"))))

(define (req path #:method [method #"GET"] #:headers [headers '()] #:bindings [bindings '()])
  (request method
           (string->url path)
           headers
           (delay bindings)
           #f
           "127.0.0.1"
           5001
           "127.0.0.1"))

(define (match-count rx s)
  (length (regexp-match* rx s)))

(module+ test
  (test-case "museum catalog has exhibit cards instead of platform tabs"
    (define html (render-page (req "/") schemas layouts))
    (check-true (regexp-match? #rx"Chinese Input Method Museum" html))
    (check-true (regexp-match? #rx"Explore Chinese input methods from history to hands-on interaction" html))
    (check-true (regexp-match? #rx"href=\"/exhibits/flypy\"" html))
    (check-true (regexp-match? #rx"href=\"/exhibits/flypy_14\"" html))
    (check-false (regexp-match? #rx"href=\"/exhibits/flypy_ice\"" html))
    (check-true (regexp-match? #rx"/layouts/flypy/preview.svg" html))
    (check-true (regexp-match? #rx"Double Pinyin" html))
    (check-true (regexp-match? #rx"Flypy double pinyin exhibit" html))
    (check-false (regexp-match? #rx"rime-artifact-chip" html))
    (check-false (regexp-match? #rx"<span class=\"rime-option-id\">flypy" html))
    (check-false (regexp-match? #rx"href=\"/\">Museum</a>" html))
    (check-true (regexp-match? #rx"Powered by Racket" html))
    (check-true (regexp-match? #rx"support-8f6d2b" html))
    (check-true (regexp-match? #rx"Support" html))
    (check-false (regexp-match? #rx"rime-platform-tabs" html))
    (check-false (regexp-match? #rx"rime-instructions" html))
    (check-false (regexp-match? #rx"type=\"checkbox\"" html))
    (check-false (regexp-match? #rx"href=\"/desktop\"" html))
    (check-false (regexp-match? #rx"htmx.org" html)))

  (test-case "catalog supports Traditional Chinese copy"
    (define html (render-page (req "/?locale=zh-Hant") schemas layouts))
    (check-true (regexp-match? #rx"<html lang=\"zh-Hant\"" html))
    (check-true (regexp-match? #rx"中文輸入博物館" html))
    (check-true (regexp-match? #rx"探索中文輸入法，從歷史脈絡到可互動的鍵盤佈局" html))
    (check-true (regexp-match? #rx"雙拼" html))
    (check-true (regexp-match? #rx"小鶴展品" html))
    (check-true (regexp-match? #rx">EN</a>" html)))

  (test-case "exhibit page shows details, artifact previews, and artifact actions"
    (define html (render-exhibit-page (req "/exhibits/flypy") schemas layouts "flypy"))
    (check-true (regexp-match? #rx"Flypy double pinyin exhibit" html))
    (check-false (regexp-match? #rx"<code>cangjie6</code>" html))
    (check-false (regexp-match? #rx"Dependencies" html))
    (check-true (regexp-match? #rx"/layouts/flypy/preview-dark.svg" html))
    (check-false (regexp-match? #rx"Keyboard layouts" html))
    (check-true (regexp-match? #rx"name=\"artifact\" value=\"rime\"" html))
    (check-true (regexp-match? #rx"name=\"artifact\" value=\"yuanshu\"" html))
    (check-true (regexp-match? #rx"<select[^>]+name=\"schemas\"" html))
    (check-equal? (match-count #rx"<select[^>]+name=\"schemas\"" html) 1)
    (check-true (regexp-match? #rx"<option[^>]+value=\"flypy\"" html))
    (check-true (regexp-match? #rx"<option[^>]+value=\"flypy_ice\"" html))
    (check-true (regexp-match? #rx"Dictionary" html))
    (check-true (regexp-match? #rx"Download Rime package" html))
    (check-true (regexp-match? #rx"Download Yuanshu package" html))
    (check-true (regexp-match? #rx"/layouts/flypy/preview.svg" html))
    (check-true (regexp-match? #rx"/skins/flypy/preview.svg" html))
    (define rime-preview-pos (regexp-match-positions #rx"/layouts/flypy/preview.svg" html))
    (define yuanshu-preview-pos (regexp-match-positions #rx"/skins/flypy/preview.svg" html))
    (define rime-pos (regexp-match-positions #rx"Download Rime package" html))
    (define yuanshu-pos (regexp-match-positions #rx"Download Yuanshu package" html))
    (check-not-false rime-preview-pos)
    (check-not-false yuanshu-preview-pos)
    (check-not-false rime-pos)
    (check-not-false yuanshu-pos)
    (check-true (< (caar rime-preview-pos) (caar rime-pos)))
    (check-true (< (caar yuanshu-preview-pos) (caar yuanshu-pos)))
    (check-false (regexp-match? #rx"rime-exhibit-meta" html))
    (check-false (regexp-match? #rx"rime-layout-title" html))
    (check-false (regexp-match? #rx"<span class=\"rime-option-id\">flypy" html)))

  (test-case "yuanshu-only exhibit omits Rime download"
    (define html (render-exhibit-page (req "/exhibits/flypy_14") schemas layouts "flypy_14"))
    (check-false (regexp-match? #rx"name=\"artifact\" value=\"rime\"" html))
    (check-true (regexp-match? #rx"name=\"artifact\" value=\"yuanshu\"" html)))

  (test-case "locale is remembered from cookie"
    (define html
      (render-page
       (req "/"
            #:headers (list (header #"Cookie" #"rime-locale=zh-Hant")))
       schemas
       layouts))
    (check-true (regexp-match? #rx"<html lang=\"zh-Hant\"" html))
    (check-true (regexp-match? #rx"中文輸入博物館" html))
    (check-true (regexp-match? #rx">EN</a>" html)))

  (test-case "form posts become artifact build profiles"
    (define request
      (req "/build"
           #:method #"POST"
           #:headers (list (header #"Content-Type" #"application/x-www-form-urlencoded"))
           #:bindings (list (binding:form #"artifact" #"yuanshu")
                            (binding:form #"schemas" #"flypy_ice"))))
    (check-true (form-request? request))
    (check-equal? (form-profile request)
                  (hash 'schemas '("flypy_ice")
                        'artifact "yuanshu")))

  (test-case "legacy desktop form posts map to rime and yuanshu artifacts"
    (define rime-request
      (req "/build"
           #:method #"POST"
           #:headers (list (header #"Content-Type" #"application/x-www-form-urlencoded"))
           #:bindings (list (binding:form #"desktop?" #"true")
                            (binding:form #"schemas" #"flypy"))))
    (define yuanshu-request
      (req "/build"
           #:method #"POST"
           #:headers (list (header #"Content-Type" #"application/x-www-form-urlencoded"))
           #:bindings (list (binding:form #"desktop?" #"false")
                            (binding:form #"schemas" #"flypy"))))
    (check-equal? (form-profile rime-request)
                  (hash 'schemas '("flypy")
                        'artifact "rime"))
    (check-equal? (form-profile yuanshu-request)
                  (hash 'schemas '("flypy")
                        'artifact "yuanshu"))))
