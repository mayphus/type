#lang racket/base

(provide (struct-out keyboard-dimension)
         keyboard-dimensions
         keyboard-dimension-ref)

(struct keyboard-dimension
  (id
   skeleton
   projection
   interactions
   target)
  #:transparent)

(define-syntax-rule (define-keyboard-dimensions name
                      (id skeleton projection (interaction ...) target) ...)
  (define name
    (list
     (keyboard-dimension 'id 'skeleton 'projection '(interaction ...) 'target)
     ...)))

(define-keyboard-dimensions keyboard-dimensions
  (standard-26 standard-26 identity-26 (standard-mobile no-swipe-down) yuanshu)
  (compact-14 compact-14 adjacent-qwerty-14 (compact-mobile no-swipe-down) yuanshu)
  (compact-18 compact-18 adjacent-qwerty-18 (compact-mobile no-swipe-down) yuanshu)
  (shuffle-17 compact-17 shuffle-17 (custom-mobile-pages no-swipe-down) yuanshu)
  (zhuyin zhuyin zhuyin-direct (zhuyin-mobile custom-mobile-pages no-swipe-down) yuanshu)
  (standard-zhuyin standard-zhuyin standard-zhuyin-direct (standard-desktop) rime))

(define keyboard-dimension-by-id
  (for/hash ((dimension (in-list keyboard-dimensions)))
    (values (keyboard-dimension-id dimension) dimension)))

(define (keyboard-dimension-ref id)
  (hash-ref keyboard-dimension-by-id
            id
            (lambda ()
              (error 'keyboard-dimension-ref "unknown keyboard dimension: ~a" id))))
