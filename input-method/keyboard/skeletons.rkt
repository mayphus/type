#lang racket/base

(provide keyboard-skeleton-definitions
         keyboard-skeleton-definition-ref
         keyboard-model-definitions
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

(define keyboard-skeleton-definitions
  `((standard-26
     (columns 10)
     (rows
      (q w e r t y u i o p)
      (a s d f g h j k l)
      (z x c v b n m))
     (row-offsets 0 1/2 0)
     (slots ,standard-key-slots))
    (compact-14
     (columns 5)
     (rows
      (qw er ty ui op)
      (as df gh jk l)
      (zx cv bn m backspace))
     (row-offsets 0 0 0)
     (slots ,standard-key-slots))
    (compact-18
     (columns 7)
     (rows
      (q we rt y u io p)
      (a sd fg h jk l)
      (z xc v bn m))
     (row-offsets 0 0 0)
     (slots ,standard-key-slots))
    (compact-17
     (columns 6)
     (rows
      (a b c d e f)
      (g h i j k)
      (l m n o p q))
     (row-offsets 0 1/2 0)
     (slots ,standard-key-slots))
    (zhuyin
     (columns 10)
     (rows
      (bo de third-tone fourth-tone zhi second-tone light-tone a ai an)
      (po te ge ji chi zi yi o ei en)
      (mo ne ke qi shi ci wu e ao ang)
      (fo le he xi ri si yu eh ou eng))
     (row-offsets 0 0 0 0)
     (slots ,standard-key-slots))))

(define keyboard-model-definitions keyboard-skeleton-definitions)

(define (keyboard-skeleton-definition-ref skeleton [default #f])
  (define model-symbol
    (cond
      [(symbol? skeleton) skeleton]
      [(string? skeleton) (string->symbol skeleton)]
      [else skeleton]))
  (define entry
    (for/first ([definition (in-list keyboard-skeleton-definitions)]
                #:when (eq? (car definition) model-symbol))
      (cdr definition)))
  (or entry default))

(define keyboard-model-definition-ref keyboard-skeleton-definition-ref)
