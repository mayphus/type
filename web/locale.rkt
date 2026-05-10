#lang racket/base

(require racket/match
         net/url
         web-server/http)

(provide app-css-href
         preview-svg-version
         t
         localized-value
         next-locale
         request-values
         request-value
         request-locale
         remember-locale-headers)

(define app-css-href "/app.css?v=20260510-artifacts")
(define preview-svg-version "20260509-zrowgap")

(define copy
  (hash
   'en
   (hash
    'title "Chinese Input Method Museum"
    'landing-copy "Explore Chinese input methods from history to hands-on interaction."
    'back "Home"
    'layouts "Keyboard layouts"
    'dependencies "Dependencies"
    'no-dependencies "No extra schema dependencies."
    'rime "Rime"
    'yuanshu "Yuanshu"
    'dictionary "Dictionary"
    'download-rime "Download Rime package"
    'download-yuanshu "Download Yuanshu package"
    'missing "Exhibit not found."
    'support "Support"
    'footer-credit "Powered by Racket on pb62"
    'language "繁")
   'zh-Hant
   (hash
    'title "中文輸入博物館"
    'landing-copy "探索中文輸入法，從歷史脈絡到可互動的鍵盤佈局。"
    'back "首頁"
    'layouts "鍵盤佈局"
    'dependencies "依賴方案"
    'no-dependencies "沒有額外方案依賴。"
    'rime "Rime"
    'yuanshu "元書"
    'dictionary "詞庫"
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
