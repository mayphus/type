#lang racket/base

(require racket/list
         racket/match
         racket/string
         web-server/http
         xml)

(provide render-page
         remember-locale-headers
         form-profile
         form-request?)

;; The Racket UI is deliberately boring HTML. The form posts directly to the
;; ZIP build path; CSS handles the immediate selected-card state.

(define htmx-script
  "https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js")

(define app-css-href "/app.css?v=20260506")

(define copy
  (hash
   'en
   (hash
    'title "Rime Config"
    'landing-copy "Build a small Rime package for the place you type most."
    'desktop-copy "Export desktop Rime schemas for Squirrel, Weasel, or fcitx-rime."
    'mobile-copy "Export Yuanshu IME schemas and matching skins for iPhone or iPad."
    'desktop "Desktop"
    'mobile "Mobile"
    'home "Home"
    'schemas "Schemas"
    'schemas-copy "Dependent schemas are added automatically."
    'skins "Skins"
    'auto "Auto"
    'summary "Summary"
    'platform "Platform"
    'summary-copy "Review the package contents, then generate the archive."
    'empty "Nothing selected yet."
    'build "Build and Download"
    'zip-help "Output is a ZIP archive."
    'yuanshu-help "Use in Yuanshu"
    'yuanshu-steps
    '("Install Yuanshu IME on iPhone or iPad."
      "Open the ZIP in Yuanshu, or use Input Schemas -> ... -> Import."
      "Remove any old skin with the same name before importing.")
    'support "Support"
    'footer-credit "Powered by 🎾 Racket · 🖥 pb62"
    'language "繁")
   'zh-Hant
   (hash
    'title "Rime 配置"
    'landing-copy "為你最常輸入的地方生成一份小而完整的 Rime 配置。"
    'desktop-copy "導出桌面 Rime 方案，可用於鼠鬚管、小狼毫或 fcitx-rime。"
    'mobile-copy "導出元書輸入法方案與配套皮膚，適合 iPhone 或 iPad。"
    'desktop "桌面"
    'mobile "移動端"
    'home "首頁"
    'schemas "方案"
    'schemas-copy "依賴方案會自動補上。"
    'skins "皮膚"
    'auto "自動"
    'summary "摘要"
    'platform "平台"
    'summary-copy "確認打包內容後即可生成壓縮檔。"
    'empty "目前尚未選擇。"
    'build "編譯並下載"
    'zip-help "輸出為 ZIP 壓縮包。"
    'yuanshu-help "如何在元書中使用"
    'yuanshu-steps
    '("先在 iPhone 或 iPad 安裝元書輸入法。"
      "用元書打開這個 ZIP，或在「輸入方案」->「...」->「導入方案」中導入。"
      "導入前請先刪除同名舊皮膚。")
    'support "支持"
    'footer-credit "Powered by 🎾 Racket · 🖥 pb62"
    'language "EN")))

(struct ui-state (route locale selected-schemas configured?)
  #:transparent)

(define (t locale key)
  (hash-ref (hash-ref copy locale) key))

(define (next-locale locale)
  (if (eq? locale 'zh-Hant) 'en 'zh-Hant))

(define (locale-param value)
  (if (equal? value "zh-Hant") 'zh-Hant 'en))

(define locale-cookie-name "rime-locale")

(define (locale-value? value)
  (or (equal? value "en")
      (equal? value "zh-Hant")))

(define (request-cookie-value req name)
  (for/first ([cookie (in-list (request-cookies req))]
              #:when (equal? (client-cookie-name cookie) name))
    (client-cookie-value cookie)))

(define (remember-locale-headers req)
  (define locale (request-value req "locale" #f))
  (if (locale-value? locale)
      (list (cookie->header
             (make-cookie locale-cookie-name locale
                          #:path "/"
                          #:max-age (* 60 60 24 365))))
      '()))

(define (route-param value fallback)
  (match value
    ["desktop" 'desktop]
    ["mobile" 'mobile]
    ["home" 'home]
    [_ fallback]))

(define (route-path route)
  (case route
    [(desktop) "/desktop"]
    [(mobile) "/mobile"]
    [else "/"]))

(define (binding-value binding)
  (and (binding:form? binding)
       (bytes->string/utf-8 (binding:form-value binding))))

(define (request-values req key)
  (for/list ([binding (in-list (request-bindings/raw req))]
             #:when (equal? (bytes->string/utf-8 (binding-id binding)) key)
             #:do [(define value (binding-value binding))]
             #:when value)
    value))

(define (request-value req key [default #f])
  (match (request-values req key)
    [(list value _ ...) value]
    [_ default]))

(define (present? req key)
  (not (null? (request-values req key))))

(define (form-request? req)
  (define headers (request-headers/raw req))
  (for/or ([header (in-list headers)])
    (and (string-ci=? (bytes->string/utf-8 (header-field header)) "content-type")
         (regexp-match? #rx#"application/x-www-form-urlencoded"
                        (header-value header)))))

(define (schema-id schema)
  (hash-ref schema 'id))

(define (schema-name schema)
  (hash-ref schema 'name (schema-id schema)))

(define (schema-mobile-only? schema)
  (hash-ref schema 'mobile-only? #f))

(define (schema-deps schema)
  (hash-ref schema 'deps '()))

(define (schema-mobile-skins schema)
  (hash-ref schema 'mobile-skins '()))

(define (schema-by-id schemas id)
  (for/first ([schema (in-list schemas)]
              #:when (equal? id (schema-id schema)))
    schema))

(define (auto-deps schemas selected)
  (let loop ([visited selected] [queue selected] [auto '()])
    (match queue
      ['() (reverse auto)]
      [(cons id rest)
       (define schema (schema-by-id schemas id))
       (define new-deps
         (filter (lambda (dep) (not (member dep visited)))
                 (if schema (schema-deps schema) '())))
       (loop (append visited new-deps)
             (append rest new-deps)
             (append new-deps auto))])))

(define (active-schema-ids schemas selected)
  (remove-duplicates (append selected (auto-deps schemas selected))))

(define (visible-schemas schemas route)
  (filter (lambda (schema)
            (or (eq? route 'mobile)
                (not (schema-mobile-only? schema))))
          schemas))

(define schema-catalog-order
  '("double-pinyin" "full-pinyin" "shape" "cantonese" "phonetic" "other"))

(define (schema-catalog-id schema)
  (match (schema-id schema)
    [(or "flypy" "flypy_ice" "flypy_14" "flypy_18" "shuffle_17") "double-pinyin"]
    [(or "luna_pinyin" "terra_pinyin" "pinyin_14") "full-pinyin"]
    ["cangjie6" "shape"]
    ["jyut6ping3" "cantonese"]
    ["bopomofo" "phonetic"]
    [_ "other"]))

(define (schema-catalog-label catalog-id)
  (hash-ref (hash "double-pinyin" "Double Pinyin"
                  "full-pinyin" "Full Pinyin"
                  "shape" "Shape"
                  "cantonese" "Cantonese"
                  "phonetic" "Phonetic"
                  "other" "Other")
            catalog-id
            catalog-id))

(define (cataloged-schemas schemas)
  (filter-map
   (lambda (catalog-id)
     (define items
       (filter (lambda (schema)
                 (equal? (schema-catalog-id schema) catalog-id))
               schemas))
     (and (pair? items) (cons catalog-id items)))
   schema-catalog-order))

(define (skin-id skin)
  (list-ref skin 0))

(define (skin-name skin)
  (define name (list-ref skin 2))
  (if (string=? name "") (skin-id skin) name))

(define (visible-skins schemas skins route selected-ids)
  (if (not (eq? route 'mobile))
      '()
      (let ([skin-ids
             (remove-duplicates
              (append-map
               (lambda (id)
                 (define schema (schema-by-id schemas id))
                 (if schema (schema-mobile-skins schema) '()))
               selected-ids))])
        (filter (lambda (skin) (member (skin-id skin) skin-ids)) skins))))

(define (selected-or-default req route)
  (define configured? (present? req "configured"))
  (define selected (request-values req "schemas"))
  (cond
    [configured? selected]
    [(eq? route 'mobile) '("flypy_14")]
    [else '("flypy")]))

(define (parse-state req route)
  (define locale
    (locale-param
     (or (request-value req "locale" #f)
         (request-cookie-value req locale-cookie-name)
         "en")))
  (define actual-route (route-param (request-value req "route" #f) route))
  (define configured? (present? req "configured"))
  (ui-state actual-route
            locale
            (selected-or-default req actual-route)
            configured?))

(define (attrs . pairs)
  (filter values pairs))

(define (input-hidden name value)
  `(input ((type "hidden") (name ,name) (value ,value))))

(define (classes . values)
  (string-join (filter (lambda (value) value) values) " "))

(define (skin-by-id skins id)
  (for/first ([skin (in-list skins)]
              #:when (equal? (skin-id skin) id))
    skin))

(define (schema-preview skin)
  `(div ((class "rime-schema-preview keyboard-preview keyboard-preview-svg-wrap"))
        (img ((class "keyboard-preview-svg")
              (loading "lazy")
              (src ,(format "/skins/~a/preview.svg" (skin-id skin)))
              (alt ,(skin-name skin))))))

(define (schema-card locale schema checked? auto? preview-skins)
  `(label ((class ,(classes "rime-option-card"
                            (and checked? "is-selected")
                            (and auto? "is-auto"))))
          (input ,(attrs `(class "rime-option-input")
                         `(type "checkbox")
                         `(name "schemas")
                         `(value ,(schema-id schema))
                         (and checked? `(checked "checked"))
                         (and auto? `(disabled "disabled"))))
        (div ((class "rime-option-head"))
             (div ((class "rime-option-copy"))
                  (div ((class "rime-option-title-row"))
                       (span ((class "rime-option-title")) ,(schema-name schema))
                       (span ((class "rime-option-id")) ,(schema-id schema))
                       ,@(if auto?
                             `((span ((class "rime-inline-note")) ,(t locale 'auto)))
                             '()))))
        ,@(if (pair? preview-skins)
              `((div ((class "rime-schema-previews"))
                     ,@(for/list ([skin (in-list preview-skins)])
                         (schema-preview skin))))
              '())))

(define (schema-card-for locale route skins selected-ids active-ids auto-ids schema)
  (define id (schema-id schema))
  (define preview-skins
    (if (eq? route 'mobile)
        (filter values
                (map (lambda (skin-id)
                       (skin-by-id skins skin-id))
                     (schema-mobile-skins schema)))
        '()))
  (schema-card locale
               schema
               (member id active-ids)
               (member id auto-ids)
               preview-skins))

(define (schema-catalog-section locale route skins selected-ids active-ids auto-ids catalog)
  (define catalog-id (car catalog))
  (define schemas (cdr catalog))
  `(section ((class "rime-schema-catalog"))
            (h3 ((class "rime-schema-catalog-title")) ,(schema-catalog-label catalog-id))
            (div ((class "rime-option-grid"))
                 ,@(for/list ([schema (in-list schemas)])
                     (schema-card-for locale route skins selected-ids active-ids auto-ids schema)))))

(define (configurator-xexpr req schemas skins #:route [fallback-route 'desktop])
  (define state (parse-state req fallback-route))
  (define route (ui-state-route state))
  (define locale (ui-state-locale state))
  (define selected-ids (ui-state-selected-schemas state))
  (define auto-ids (auto-deps schemas selected-ids))
  (define active-ids (active-schema-ids schemas selected-ids))
  `(form ((id "configurator-form")
          (class "rime-config-grid")
          (method "post")
          (action "/build"))
     ,(input-hidden "configured" "1")
     ,(input-hidden "route" (symbol->string route))
     ,(input-hidden "locale" (symbol->string locale))
     ,(input-hidden "desktop?" (if (eq? route 'desktop) "true" "false"))
     (div ((class "rime-primary-column"))
          (section ((class "rime-section"))
                   (div ((class "rime-schema-catalogs"))
                        ,@(for/list ([catalog (in-list (cataloged-schemas
                                                        (visible-schemas schemas route)))])
                            (schema-catalog-section locale
                                                    route
                                                    skins
                                                    selected-ids
                                                    active-ids
                                                    auto-ids
                                                    catalog)))
                   (div ((class "rime-form-actions"))
                        (button ((class "rime-build-button rime-flow-build-button")
                                 (type "submit"))
                                ,(t locale 'build)))))))

(define (page-shell req schemas skins route)
  (define state (parse-state req route))
  (define locale (ui-state-locale state))
  `(html ((lang ,(if (eq? locale 'zh-Hant) "zh-Hant" "en")))
         (head
          (meta ((charset "utf-8")))
          (meta ((name "viewport") (content "width=device-width, initial-scale=1")))
          (title ,(t locale 'title))
          (link ((rel "stylesheet") (href ,app-css-href)))
          (script ((src ,htmx-script)
                   (defer "defer")) ""))
         (body
          (main ((id "app"))
                (div ((class ,(classes "rime-config-shell"
                                       (and (eq? route 'home) "rime-landing-shell"))))
                     (section ((class "rime-hero-card"))
                              (div ((class "rime-hero-head"))
                                   (div
                                    ,@(if (eq? route 'home)
                                          '()
                                          `((a ((class "rime-back-link")
                                               (href "/")) ,(t locale 'home))))
                                   (h1 ((class "page-title")) ,(t locale 'title))
                                   (p ((class "rime-section-copy"))
                                      ,(case route
                                         [(desktop) (t locale 'desktop-copy)]
                                         [(mobile) (t locale 'mobile-copy)]
                                         [else (t locale 'landing-copy)]))))
                              ,@(if (eq? route 'home)
                                    '()
                                    `((nav ((class "rime-platform-tabs"))
                                           (a ((class ,(classes "rime-platform-tab"
                                                                (and (eq? route 'desktop) "is-active")))
                                               (href "/desktop")) ,(t locale 'desktop))
                                           (a ((class ,(classes "rime-platform-tab"
                                                                (and (eq? route 'mobile) "is-active")))
                                               (href "/mobile")) ,(t locale 'mobile))))))
                     ,@(if (eq? route 'home)
                           `((div ((class "rime-entry-grid"))
                                  (a ((class "rime-entry-card") (href "/desktop"))
                                     (span ((class "rime-option-title")) ,(t locale 'desktop))
                                     (span ((class "rime-section-copy")) ,(t locale 'desktop-copy)))
                                  (a ((class "rime-entry-card") (href "/mobile"))
                                     (span ((class "rime-option-title")) ,(t locale 'mobile))
                                     (span ((class "rime-section-copy")) ,(t locale 'mobile-copy)))))
                           `((div ((id "configurator"))
                                  ,(configurator-xexpr req schemas skins #:route route))))
                     (footer ((class "rime-footer"))
                             (span ((class "rime-footer-credit")) ,(t locale 'footer-credit))
                             (div ((class "rime-footer-support"))
                                  (span ((class "rime-footer-support-label")) ,(t locale 'support))
                                  (img ((class "rime-footer-support-image")
                                        (src "/support.svg")
                                        (alt ,(t locale 'support)))))
                             (a ((class "rime-language-toggle rime-footer-language")
                                 (href ,(format "~a?locale=~a"
                                                (route-path route)
                                                (symbol->string (next-locale locale)))))
                                ,(t locale 'language))))))))

(define (render-page req schemas skins #:route [route 'home])
  (xexpr->string (page-shell req schemas skins route)))

(define (form-profile req)
  (define schemas (request-values req "schemas"))
  (define desktop? (equal? (request-value req "desktop?" "true") "true"))
  (hash 'schemas schemas
        'desktop? desktop?))
