#lang racket/base

(require "models.rkt"
         "legends.rkt"
         "shapes.rkt")

(provide keyboard-layout-definitions
         keyboard-layout-definition-ref
         keyboard-legend-definitions
         keyboard-legend-definition-ref
         keyboard-legend-text
         keyboard-model-definitions
         keyboard-model-definition-ref
         keyboard-shape-definition-ref)

;; Static upstream schemas do not have schema modules, so their reusable printed
;; keyboard legends live here. Generated schemas still own their local layouts.
(define keyboard-layout-definitions
  '((wubi86
     (meta
      (name "Wubi 86" "五筆86")
      (summary "Wubi 86 root legends on standard QWERTY rows.")
      (features
       "Wubi root groups centered on letter keys"
       "Z key marks pinyin reverse lookup"))
     (phone-layout
      (layers abc wubi)
      (positions
       [abc top]
       [wubi center])
      (fonts
       [abc 10 #:secondary]
       [wubi 12 #:primary]))
     (ipad-layout
      (layers abc wubi)
      (size "1.1/16")
      (positions
       [abc top]
       [wubi center])
      (fonts
       [abc 11 #:secondary]
       [wubi 14 #:primary])))
    (stroke
     (meta
      (name "Stroke" "五筆畫")
      (summary "Five-stroke legends and compatibility aliases.")
      (features
       "Main h/s/p/n/z stroke keys"
       "Mac stroke alias keys j/k/l/u/i"))
     (phone-layout
      (layers abc stroke)
      (positions
       [abc top]
       [stroke center])
      (fonts
       [abc 10 #:secondary]
       [stroke 22 #:primary]))
     (ipad-layout
      (layers abc stroke)
      (size "1.1/16")
      (positions
       [abc top]
       [stroke center])
      (fonts
       [abc 11 #:secondary]
       [stroke 24 #:primary])))
    (double_pinyin_zrm
     (meta
      (name "Double Pinyin ZRM" "自然碼雙拼")
      (summary "Ziranma double-pinyin final legends.")
      (features "Ziranma finals centered on QWERTY keys"))
     (phone-layout
      (layers abc zrm)
      (positions [abc top] [zrm center])
      (fonts [abc 10 #:secondary] [zrm 11 #:primary]))
     (ipad-layout
      (layers abc zrm)
      (size "1.1/16")
      (positions [abc top] [zrm center])
      (fonts [abc 11 #:secondary] [zrm 13 #:primary])))
    (double_pinyin_abc
     (meta
      (name "Double Pinyin ABC" "智能ABC雙拼")
      (summary "Intelligent ABC double-pinyin legends.")
      (features "ABC finals and special initials centered on QWERTY keys"))
     (phone-layout
      (layers abc abc-dp)
      (positions [abc top] [abc-dp center])
      (fonts [abc 10 #:secondary] [abc-dp 11 #:primary]))
     (ipad-layout
      (layers abc abc-dp)
      (size "1.1/16")
      (positions [abc top] [abc-dp center])
      (fonts [abc 11 #:secondary] [abc-dp 13 #:primary])))
    (double_pinyin_mspy
     (meta
      (name "Double Pinyin MSPY" "微軟雙拼")
      (summary "Microsoft double-pinyin final legends.")
      (features "MSPY finals centered on QWERTY keys"))
     (phone-layout
      (layers abc mspy)
      (positions [abc top] [mspy center])
      (fonts [abc 10 #:secondary] [mspy 11 #:primary]))
     (ipad-layout
      (layers abc mspy)
      (size "1.1/16")
      (positions [abc top] [mspy center])
      (fonts [abc 11 #:secondary] [mspy 13 #:primary])))
    (double_pinyin_pyjj
     (meta
      (name "Double Pinyin PYJJ" "拼音加加雙拼")
      (summary "Pinyin Jiajia double-pinyin final legends.")
      (features "PYJJ finals centered on QWERTY keys"))
     (phone-layout
      (layers abc pyjj)
      (positions [abc top] [pyjj center])
      (fonts [abc 10 #:secondary] [pyjj 11 #:primary]))
     (ipad-layout
      (layers abc pyjj)
      (size "1.1/16")
      (positions [abc top] [pyjj center])
      (fonts [abc 11 #:secondary] [pyjj 13 #:primary])))
    (double_pinyin_st
     (meta
      (name "Double Pinyin ST" "四通雙拼")
      (summary "Stone double-pinyin final legends.")
      (features "ST finals centered on QWERTY keys"))
     (phone-layout
      (layers abc st)
      (positions [abc top] [st center])
      (fonts [abc 10 #:secondary] [st 11 #:primary]))
     (ipad-layout
      (layers abc st)
      (size "1.1/16")
      (positions [abc top] [st center])
      (fonts [abc 11 #:secondary] [st 13 #:primary])))))

(define (catalog-symbol value)
  (cond
    [(symbol? value) value]
    [(string? value) (string->symbol value)]
    [else value]))

(define (catalog-definition-ref definitions id [default #f])
  (define id-symbol (catalog-symbol id))
  (define body
    (for/first ([clause (in-list definitions)]
                #:when (eq? (car clause) id-symbol))
      (cdr clause)))
  (or body default))

(define (keyboard-layout-definition-ref layout [default #f])
  (catalog-definition-ref keyboard-layout-definitions layout default))

(define (keyboard-shape-definition-ref shape [default #f])
  (catalog-definition-ref keyboard-shape-definitions shape default))
