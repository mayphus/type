#lang racket/base

(provide define-catalog
         catalog-definition-ref
         catalog-symbol)

(define-syntax-rule (define-catalog name (id body ...) ...)
  (define name
    '((id body ...) ...)))

(define (catalog-symbol value)
  (cond
    ((symbol? value) value)
    ((string? value) (string->symbol value))
    (else value)))

(define (catalog-definition-ref definitions id (default #f))
  (define id-symbol (catalog-symbol id))
  (define body
    (for/first ((clause (in-list definitions))
                #:when (eq? (car clause) id-symbol))
      (cdr clause)))
  (or body default))
