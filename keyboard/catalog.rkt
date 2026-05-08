#lang racket/base

(require "models.rkt"
         "shapes.rkt")

(provide keyboard-layout-definitions
         keyboard-layout-definition-ref
         keyboard-model-definitions
         keyboard-model-definition-ref
         keyboard-shape-definition-ref)

;; Schema modules own concrete printed keyboard layouts. Keep this empty shared
;; catalog only as the fallback API for older build code paths.
(define keyboard-layout-definitions '())

(define (catalog-symbol value)
  (cond
    [(symbol? value) value]
    [(string? value) (string->symbol value)]
    [else value]))

(define (catalog-definition-ref definitions id [default #f])
  (define id-symbol (catalog-symbol id))
  (define body
    (for/list ([clause (in-list definitions)]
               #:when (eq? (car clause) id-symbol))
      (cdr clause)))
  (if (null? body) default body))

(define (keyboard-layout-definition-ref layout [default #f])
  (catalog-definition-ref keyboard-layout-definitions layout default))

(define (keyboard-shape-definition-ref shape [default #f])
  (catalog-definition-ref keyboard-shape-definitions shape default))
