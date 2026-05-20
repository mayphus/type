#lang racket/base

(require rackunit
         net/url
         racket/promise
         web-server/http
         "../web/pages.rkt"
         "../web/forms.rkt")

(define schemas
  (list (hash 'id "double-pinyin-flypy"
              'slug "double-pinyin-flypy"
              'name "小鶴"
              'names (hash 'en "Flypy" 'zh-Hant "小鶴")
              'description "Flypy double pinyin exhibit."
              'descriptions (hash 'en "Flypy double pinyin exhibit."
                                  'zh-Hant "小鶴展品。")
              'input-method? #t
              'schema-id "double-pinyin-flypy"
              'keymap 'flypy
              'keyboard 'standard-26
              'layout "flypy"
              'definition-lisp "(define-input-method\n  \"double-pinyin-flypy\"\n  #:schema \"double-pinyin-flypy\"\n  #:keymap 'flypy\n  #:keyboard 'standard-26\n  #:layout \"flypy\")"
              'deps '("cangjie6")
              'artifacts '("rime" "yuanshu")
              'keyboard-layouts '("double-pinyin-flypy"))
        (hash 'id "double-pinyin-flypy-14"
              'slug "double-pinyin-flypy-14"
              'name "小鶴十四鍵"
              'names (hash 'en "Flypy 14" 'zh-Hant "小鶴十四鍵")
              'description "A compact Yuanshu-only 14-key exhibit."
              'descriptions (hash 'en "A compact Yuanshu-only 14-key exhibit."
                                  'zh-Hant "緊湊的元書十四鍵展品。")
              'input-method? #t
              'schema-id "double-pinyin-flypy"
              'keymap 'flypy
              'keyboard 'compact-14
              'layout "flypy_14"
              'definition-lisp "(define-input-method\n  \"double-pinyin-flypy-14\"\n  #:schema \"double-pinyin-flypy\"\n  #:keymap 'flypy\n  #:keyboard 'compact-14\n  #:layout \"flypy_14\")"
              'deps '("cangjie6")
              'artifacts '("yuanshu")
              'keyboard-layouts '("double-pinyin-flypy-14"))
        (hash 'id "cangjie6"
              'slug "cangjie6"
              'name "Cangjie 6"
              'names (hash 'en "Cangjie 6" 'zh-Hant "倉頡六代")
              'description "Static Cangjie support schema."
              'descriptions (hash 'en "Static Cangjie support schema."
                                  'zh-Hant "倉頡支援方案。")
              'input-method? #t
              'schema-id "cangjie6"
              'keymap 'cangjie6
              'keyboard 'standard-26
              'layout "cangjie6"
              'definition-lisp "(define-input-method\n  \"cangjie6\")"
              'deps '()
              'artifacts '("rime")
              'keyboard-layouts '("cangjie6"))
        (hash 'id "cangjie5"
              'slug "cangjie5"
              'name "Cangjie 5"
              'names (hash 'en "Cangjie 5" 'zh-Hant "倉頡五代")
              'description "Upstream Rime fifth-generation Cangjie shape input."
              'descriptions (hash 'en "Upstream Rime fifth-generation Cangjie shape input."
                                  'zh-Hant "上游 Rime 第五代倉頡字形輸入方案。")
              'input-method? #t
              'schema-id "cangjie6"
              'keymap 'cangjie5
              'keyboard 'standard-26
              'layout "cangjie5"
              'definition-lisp "(define-input-method\n  \"cangjie5\")"
              'deps '()
              'artifacts '("rime")
              'keyboard-layouts '("cangjie5"))))

(define layouts
  (list (hash 'id "double-pinyin-flypy"
              'schemas '("double-pinyin-flypy")
              'name "小鶴"
              'names (hash 'en "Flypy" 'zh-Hant "小鶴")
              'preview-svgs (hash 'light "<svg/>")
              'skin-preview-svgs (hash 'light "<svg/>"))
        (hash 'id "double-pinyin-flypy-14"
              'schemas '("double-pinyin-flypy-14")
              'name "小鶴十四鍵"
              'names (hash 'en "Flypy 14-Key" 'zh-Hant "小鶴十四鍵")
              'preview-svgs (hash 'light "<svg/>")
              'skin-preview-svgs (hash 'light "<svg/>"))
        (hash 'id "cangjie6"
              'schemas '("cangjie6")
              'name "Cangjie 6"
              'names (hash 'en "Cangjie 6" 'zh-Hant "倉頡六代")
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
  (test-case "museum home has exhibit cards instead of platform tabs"
    (define html (render-page (req "/") schemas layouts))
    (check-true (regexp-match? #rx"Chinese Input Method Museum" html))
    (check-false (regexp-match? #rx"Explore Chinese input methods from history to hands-on interaction" html))
    (check-true (regexp-match? #rx"href=\"/exhibits/double-pinyin-flypy\"" html))
    (check-false (regexp-match? #rx"href=\"/exhibits/double-pinyin-flypy\\?platform=desktop\"" html))
    (check-false (regexp-match? #rx"href=\"/exhibits/double-pinyin-flypy\\?platform=mobile\"" html))
    (check-equal? (match-count #rx"href=\"/exhibits/double-pinyin-flypy\"" html) 1)
    (check-true (regexp-match? #rx"href=\"/exhibits/double-pinyin-flypy-14\"" html))
    (check-true (regexp-match? #rx"href=\"/exhibits/cangjie6\"" html))
    (check-equal? (match-count #rx"href=\"/exhibits/cangjie6\"" html) 1)
    (check-equal? (match-count #rx"href=\"/exhibits/cangjie5\"" html) 1)
    (check-false (regexp-match? #rx"id=\"filter-desktop\"" html))
    (check-false (regexp-match? #rx"id=\"filter-mobile\"" html))
    (check-false (regexp-match? #rx"rime-category-filter" html))
    (check-false (regexp-match? #rx"data-platforms=" html))
    (check-false (regexp-match? #rx"data-card-platform=" html))
    (check-false (regexp-match? #rx"data-href=" html))
    (check-true (regexp-match? #rx"/schemas/double-pinyin-flypy/preview.svg" html))
    (check-false (regexp-match? #rx"/schemas/double-pinyin-flypy/skin-preview.svg" html))
    (check-true (regexp-match? #rx"/schemas/double-pinyin-flypy-14/preview.svg" html))
    (check-false (regexp-match? #rx"/schemas/double-pinyin-flypy-14/skin-preview.svg" html))
    (check-false (regexp-match? #rx"Double Pinyin: Flypy" html))
    (check-false (regexp-match? #rx"rime-schema-preview--desktop" html))
    (check-false (regexp-match? #rx"rime-schema-preview--mobile" html))
    (check-false (regexp-match? #rx"rime-platform-chip" html))
    (check-true (regexp-match? #rx"Double Pinyin" html))
    (check-false (regexp-match? #rx"Flypy double pinyin exhibit" html))
    (check-false (regexp-match? #rx"Compact phonetic systems" html))
    (check-false (regexp-match? #rx"rime-artifact-chip" html))
    (check-false (regexp-match? #rx"<span class=\"rime-option-id\">flypy" html))
    (check-false (regexp-match? #rx"href=\"/\">Museum</a>" html))
    (check-true (regexp-match? #rx"href=\"https://github.com/mayphus/input-foundry\"" html))
    (check-true (regexp-match? #rx"href=\"https://zh.mayphus.org\"" html))
    (check-true (regexp-match? #rx"Powered by Racket" html))
    (check-true (regexp-match? #rx"support-8f6d2b" html))
    (check-false (regexp-match? #rx">Support<" html))
    (check-false (regexp-match? #rx"rime-platform-tabs" html))
    (check-false (regexp-match? #rx"rime-instructions" html))
    (check-false (regexp-match? #rx"type=\"checkbox\"" html))
    (check-false (regexp-match? #rx"href=\"/desktop\"" html))
    (check-false (regexp-match? #rx"htmx.org" html)))

  (test-case "home supports Traditional Chinese copy"
    (define html (render-page (req "/?locale=zh-Hant") schemas layouts))
    (check-true (regexp-match? #rx"<html lang=\"zh-Hant\"" html))
    (check-true (regexp-match? #rx"中文輸入博物館" html))
    (check-false (regexp-match? #rx"探索中文輸入法，從歷史脈絡到可互動的鍵盤佈局" html))
    (check-true (regexp-match? #rx"雙拼" html))
    (check-false (regexp-match? #rx"桌面" html))
    (check-false (regexp-match? #rx"移動" html))
    (check-false (regexp-match? #rx"小鶴展品" html))
    (check-true (regexp-match? #rx">EN</a>" html)))

  (test-case "exhibit page shows target previews with related artifact actions"
    (define html (render-exhibit-page (req "/exhibits/double-pinyin-flypy") schemas layouts "double-pinyin-flypy"))
    (check-false (regexp-match? #rx"Flypy double pinyin exhibit" html))
    (check-false (regexp-match? #rx"rime-hero-copy" html))
    (check-false (regexp-match? #rx"<code>cangjie6</code>" html))
    (check-false (regexp-match? #rx"Dependencies" html))
    (check-true (regexp-match? #rx"/schemas/double-pinyin-flypy/desktop-preview-dark.svg" html))
    (check-false (regexp-match? #rx"Keyboard layouts" html))
    (check-true (regexp-match? #rx"name=\"artifact\" value=\"yuanshu\"" html))
    (check-true (regexp-match? #rx"name=\"artifact\" value=\"rime\"" html))
    (check-false (regexp-match? #rx"<select[^>]+name=\"schemas\"" html))
    (check-true (regexp-match? #rx"type=\"hidden\" name=\"schemas\" value=\"double-pinyin-flypy\"" html))
    (check-false (regexp-match? #rx"Dictionary" html))
    (check-false (regexp-match? #rx"Download package" html))
    (check-equal? (match-count #rx"rime-target-add-button[\" ]" html) 2)
    (check-true (regexp-match? #rx"Add to bundle: Desktop" html))
    (check-true (regexp-match? #rx"Add to bundle: Mobile" html))
    (check-equal? (match-count #rx"rime-target-download-form" html) 2)
    (check-false (regexp-match? #rx"rime-exhibit-download" html))
    (check-true (regexp-match? #rx"/schemas/double-pinyin-flypy/desktop-preview.svg" html))
    (check-true (regexp-match? #rx"/schemas/double-pinyin-flypy/skin-preview.svg" html))
    (check-true (regexp-match? #rx"rime-target-preview-desktop" html))
    (check-true (regexp-match? #rx"rime-target-preview-mobile" html))
    (check-true (regexp-match? #rx"rime-definition-panel" html))
    (check-false (regexp-match? #rx"Definition" html))
    (check-false (regexp-match? #rx"rime-definition-meta" html))
    (check-true (regexp-match? #rx"define-input-method" html))
    (check-true (regexp-match? #rx"\\(define-input-method \"double-pinyin-flypy\"" html))
    (check-false (regexp-match? #rx"#:schema" html))
    (check-true (regexp-match? #rx"double-pinyin-flypy" html))
    (check-false (regexp-match? #rx"  &quot;double-pinyin-flypy&quot;" html))
    (check-true (regexp-match? #rx"#:keyboard 'standard-26" html))
    (check-false (regexp-match? #rx"rime-exhibit-meta" html))
    (check-false (regexp-match? #rx"rime-layout-title" html))
    (check-false (regexp-match? #rx"<span class=\"rime-option-id\">flypy" html)))

  (test-case "desktop query still shows all target previews"
    (define html (render-exhibit-page (req "/exhibits/double-pinyin-flypy?platform=desktop") schemas layouts "double-pinyin-flypy"))
    (check-true (regexp-match? #rx"name=\"artifact\" value=\"rime\"" html))
    (check-true (regexp-match? #rx"name=\"artifact\" value=\"yuanshu\"" html))
    (check-true (regexp-match? #rx"/schemas/double-pinyin-flypy/desktop-preview.svg" html))
    (check-true (regexp-match? #rx"/schemas/double-pinyin-flypy/skin-preview.svg" html))
    (check-true (regexp-match? #rx"rime-target-add-button" html)))

  (test-case "yuanshu-only exhibit omits Rime download"
    (define html (render-exhibit-page (req "/exhibits/double-pinyin-flypy-14") schemas layouts "double-pinyin-flypy-14"))
    (check-false (regexp-match? #rx"name=\"artifact\" value=\"rime\"" html))
    (check-true (regexp-match? #rx"name=\"artifact\" value=\"yuanshu\"" html))
    (check-true (regexp-match? #rx"#:keyboard 'compact-14" html))
    (check-true (regexp-match? #rx"#:layout" html))
    (check-true (regexp-match? #rx"flypy_14" html)))

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
                            (binding:form #"schemas" #"double-pinyin-flypy-14"))))
    (check-true (form-request? request))
    (check-equal? (form-profile request)
                  (hash 'schemas '("double-pinyin-flypy-14")
                        'artifact "yuanshu")))

  (test-case "legacy desktop form posts map to rime and yuanshu artifacts"
    (define rime-request
      (req "/build"
           #:method #"POST"
           #:headers (list (header #"Content-Type" #"application/x-www-form-urlencoded"))
           #:bindings (list (binding:form #"desktop?" #"true")
                            (binding:form #"schemas" #"double-pinyin-flypy"))))
    (define yuanshu-request
      (req "/build"
           #:method #"POST"
           #:headers (list (header #"Content-Type" #"application/x-www-form-urlencoded"))
           #:bindings (list (binding:form #"desktop?" #"false")
                            (binding:form #"schemas" #"double-pinyin-flypy"))))
    (check-equal? (form-profile rime-request)
                  (hash 'schemas '("double-pinyin-flypy")
                        'artifact "rime"))
    (check-equal? (form-profile yuanshu-request)
                  (hash 'schemas '("double-pinyin-flypy")
                        'artifact "yuanshu"))))
