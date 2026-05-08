#lang racket/base

(require web-server/http
         "locale.rkt")

(provide form-request?
         form-profile)

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
