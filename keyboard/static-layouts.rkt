#lang racket/base

(require "../dsl/keyboard.rkt")

(provide keyboard-layout-definitions
         keyboard-layout-definition-ref)

(define-syntax-rule (define-static-keyboard-layouts name
                      (id
                       #:name english-name chinese-name
                       #:summary summary
                       #:features (feature ...)
                       #:layer layer
                       #:phone-size phone-size
                       #:ipad-size ipad-size) ...)
  (define name
    '((id
       (meta
        (name english-name chinese-name)
        (summary summary)
        (features feature ...))
       (phone-layout
        (layers abc layer)
        (positions (abc top) (layer center))
        (fonts (abc 10 #:secondary) (layer phone-size #:primary)))
       (ipad-layout
        (layers abc layer)
        (size "1.1/16")
        (positions (abc top) (layer center))
        (fonts (abc 11 #:secondary) (layer ipad-size #:primary))))
      ...)))

;; Static upstream schemas do not have schema modules, so their reusable printed
;; keyboard legends live here. Generated schemas still own their local layouts.
(define-static-keyboard-layouts keyboard-layout-definitions
  (wubi86
   #:name "Wubi 86" "五筆86"
   #:summary "Wubi 86 root legends on standard QWERTY rows."
   #:features ("Wubi root groups centered on letter keys"
               "Z key marks pinyin reverse lookup")
   #:layer wubi
   #:phone-size 12
   #:ipad-size 14)
  (stroke
   #:name "Stroke" "五筆畫"
   #:summary "Five-stroke legends and compatibility aliases."
   #:features ("Main h/s/p/n/z stroke keys"
               "Mac stroke alias keys j/k/l/u/i")
   #:layer stroke
   #:phone-size 22
   #:ipad-size 24)
  (double_pinyin_zrm
   #:name "Double Pinyin ZRM" "自然碼雙拼"
   #:summary "Ziranma double-pinyin final legends."
   #:features ("Ziranma finals centered on QWERTY keys")
   #:layer zrm
   #:phone-size 11
   #:ipad-size 13)
  (double_pinyin_abc
   #:name "Double Pinyin ABC" "智能ABC雙拼"
   #:summary "Intelligent ABC double-pinyin legends."
   #:features ("ABC finals and special initials centered on QWERTY keys")
   #:layer abc-dp
   #:phone-size 11
   #:ipad-size 13)
  (double_pinyin_mspy
   #:name "Double Pinyin MSPY" "微軟雙拼"
   #:summary "Microsoft double-pinyin final legends."
   #:features ("MSPY finals centered on QWERTY keys")
   #:layer mspy
   #:phone-size 11
   #:ipad-size 13)
  (double_pinyin_pyjj
   #:name "Double Pinyin PYJJ" "拼音加加雙拼"
   #:summary "Pinyin Jiajia double-pinyin final legends."
   #:features ("PYJJ finals centered on QWERTY keys")
   #:layer pyjj
   #:phone-size 11
   #:ipad-size 13)
  (double_pinyin_st
   #:name "Double Pinyin ST" "四通雙拼"
   #:summary "Stone double-pinyin final legends."
   #:features ("ST finals centered on QWERTY keys")
   #:layer st
   #:phone-size 11
   #:ipad-size 13))

(define (keyboard-layout-definition-ref layout (default #f))
  (catalog-definition-ref keyboard-layout-definitions layout default))
