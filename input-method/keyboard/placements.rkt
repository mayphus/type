#lang racket/base

(provide keyboard-placement-definitions
         keyboard-placement-definition-ref)

(define keyboard-placement-definitions
  '((standard-center
     (summary "Single primary legend centered on each key.")
     (positions [abc center])
     (fonts [abc 25 #:primary #:weight bold]))
    (standard-top-center
     (summary "Secondary Latin key on top with method-specific legend centered.")
     (positions [abc top])
     (fonts [abc 10 #:secondary]))
    (double-pinyin-center
     (summary "Double-pinyin finals centered below a small Latin key label.")
     (positions [abc top] [double-pinyin center])
     (fonts [abc 10 #:secondary] [double-pinyin 11 #:primary]))
    (compact-center
     (summary "Merged-key compact layouts use one centered primary label.")
     (positions [label center]))
    (split-flypy
     (summary "Flypy double labels split across center and bottom slots.")
     (positions [abc top] [flypy-single bottom] [flypy-top center] [flypy-bottom bottom]))))

(define (keyboard-placement-definition-ref placement [default #f])
  (define placement-symbol
    (cond
      [(symbol? placement) placement]
      [(string? placement) (string->symbol placement)]
      [else placement]))
  (define entry
    (for/first ([definition (in-list keyboard-placement-definitions)]
                #:when (eq? (car definition) placement-symbol))
      (cdr definition)))
  (or entry default))
