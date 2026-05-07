#lang racket/base

(require rackunit
         net/url
         racket/promise
         web-server/http
         "../web-ui.rkt")

(define schemas
  (list (hash 'id "flypy"
              'name "小鶴雙拼"
              'deps '()
              'mobile-skins '("flypy")
              'mobile-only? #f)
        (hash 'id "flypy_14"
              'name "小鶴十四鍵"
              'deps '("flypy")
              'mobile-only? #t
              'mobile-skins '("flypy_14"))))

(define skins
  (list (list "flypy" '("flypy") "小鶴雙拼" #f (hash 'light "<svg/>"))
        (list "flypy_14" '("flypy_14") "小鶴十四鍵" #f (hash 'light "<svg/>"))))

(define (req path #:method [method #"GET"] #:headers [headers '()] #:bindings [bindings '()])
  (request method
           (string->url path)
           headers
           (delay bindings)
           #f
           "127.0.0.1"
           5001
           "127.0.0.1"))

(module+ test
  (test-case "mobile page includes only global instructions before preview cards"
    (define html (render-page (req "/") schemas skins #:route 'mobile))
    (check-true (regexp-match? #rx"Pick the keyboard preview you want" html))
    (check-true (regexp-match? #rx"Required dependencies are added automatically" html))
    (check-true (regexp-match? #rx"小鶴雙拼" html))
    (check-true (regexp-match? #rx"/skins/flypy/preview.svg" html))
    (check-false (regexp-match? #rx"Common User" html))
    (check-false (regexp-match? #rx"Static files" html))
    (check-false (regexp-match? #rx"href=\"/docs\"" html)))

  (test-case "global instructions support Traditional Chinese copy"
    (define html (render-page (req "/?locale=zh-Hant") schemas skins #:route 'mobile))
    (check-true (regexp-match? #rx"<html lang=\"zh-Hant\"" html))
    (check-true (regexp-match? #rx"選擇你想要的鍵盤預覽" html))
    (check-true (regexp-match? #rx"需要的依賴方案會自動加入" html))
    (check-false (regexp-match? #rx"Common User" html)))

  (test-case "home page defaults to mobile configurator"
    (define html (render-page (req "/") schemas skins #:route 'home))
    (check-true (regexp-match? #rx"rime-platform-tabs" html))
    (check-false (regexp-match? #rx"rime-entry-grid" html))
    (check-true (regexp-match? #rx"rime-schema-catalog" html))
    (check-true (regexp-match? #rx"value=\"flypy\" checked=\"checked\"" html))
    (check-true (regexp-match? #rx"href=\"/desktop\"" html))
    (check-true (regexp-match? #rx"href=\"/\"" html))
    (check-true (regexp-match? #rx"<del class=\"rime-unready-device\">iPad</del>\\."
                               html))
    (check-false (regexp-match? #rx"not ready" html))
    (check-true (regexp-match? #rx"href=\"/\"[^>]*>Mobile</a><a class=\"rime-platform-tab\" href=\"/desktop\""
                               html)))

  (test-case "mobile page defaults to the standard flypy schema"
    (define html (render-page (req "/") schemas skins #:route 'mobile))
    (check-true (regexp-match? #rx"小鶴雙拼" html))
    (check-true (regexp-match? #rx"/skins/flypy/preview.svg" html))
    (check-true (regexp-match? #rx"/skins/flypy/preview-dark.svg" html))
    (check-true (regexp-match? #rx"value=\"flypy\" checked=\"checked\"" html))
    (check-false (regexp-match? #rx"value=\"flypy_14\" checked=\"checked\"" html))
    (check-false (regexp-match? #rx"disabled=\"disabled\"" html))
    (check-true (regexp-match? #rx"prefers-color-scheme: dark" html))
    (check-true (regexp-match? #rx"rime-schema-previews" html))
    (check-true (regexp-match? #rx"rime-schema-catalog" html))
    (check-true (regexp-match? #rx"Double Pinyin" html))
    (check-false (regexp-match? #rx"Dependent schemas are added automatically" html))
    (check-false (regexp-match? #rx"rime-skin-layout" html))
    (check-false (regexp-match? #rx"rime-option-toggle" html))
    (check-true (regexp-match? #rx"rime-option-input" html))
    (check-true (regexp-match? #rx"rime-flow-build-button" html))
    (check-false (regexp-match? #rx"form=\"configurator-form\"" html))
    (check-true (regexp-match? #rx"Powered by" html))
    (check-true (regexp-match? #rx"rime-footer-support-image" html))
    (check-true (regexp-match? #rx"src=\"/support-8f6d2b.svg\"" html))
    (check-true (regexp-match? #rx"rime-footer-language" html))
    (check-false (regexp-match? #rx"rime-summary-column" html))
    (check-true (regexp-match? #rx"htmx.org" html))
    (check-false (regexp-match? #rx"/app.js" html)))

  (test-case "locale is remembered from cookie"
    (define html
      (render-page
       (req "/"
            #:headers (list (header #"Cookie" #"rime-locale=zh-Hant")))
       schemas
       skins
       #:route 'mobile))
    (check-true (regexp-match? #rx"<html lang=\"zh-Hant\"" html))
    (check-true (regexp-match? #rx"Rime 配置" html))
    (check-true (regexp-match? #rx">EN</a>" html)))

  (test-case "form posts become build profiles"
    (define request
      (req "/build"
           #:method #"POST"
           #:headers (list (header #"Content-Type" #"application/x-www-form-urlencoded"))
           #:bindings (list (binding:form #"desktop?" #"false")
                            (binding:form #"schemas" #"flypy_14"))))
    (check-true (form-request? request))
    (check-equal? (form-profile request)
                  (hash 'schemas '("flypy_14")
                        'desktop? #f))))
