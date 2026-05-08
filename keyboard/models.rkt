#lang racket/base

(provide keyboard-model-definitions
         keyboard-model-definition-ref)

(define standard-key-slots
  '((center #:font-size 25 #:role primary)
    (left #:font-size 10 #:role secondary)
    (right #:font-size 10 #:role secondary)
    (top #:font-size 10 #:role secondary)
    (bottom #:font-size 10 #:role secondary)
    (top-left #:font-size 10 #:role secondary)
    (top-right #:font-size 10 #:role secondary)
    (bottom-left #:font-size 10 #:role secondary)
    (bottom-right #:font-size 10 #:role secondary)))

(define keyboard-model-definitions
  `((standard-26
     (rows
      (q w e r t y u i o p)
      (a s d f g h j k l)
      (z x c v b n m))
     (slots ,standard-key-slots))))

(define (keyboard-model-definition-ref model [default #f])
  (define model-symbol
    (cond
      [(symbol? model) model]
      [(string? model) (string->symbol model)]
      [else model]))
  (define entry
    (for/first ([definition (in-list keyboard-model-definitions)]
                #:when (eq? (car definition) model-symbol))
      (cdr definition)))
  (or entry default))
