#lang racket/base

(require racket/hash
         "../core/dsl.rkt"
         "../core/visual-policy.rkt"
         "../keysets/pinyin-common.rkt"
         "flypy18-page.rkt"
         "flypy18-bases.rkt"
         "phone-layout-rows.rkt")

(provide pinyin-14-iphone-pinyin-files)

(define five-column-size
  (square-key-size "225/1125"))

(define keyboard-layout
  (array
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "qw14Button"])
                            (object ["Cell" "er14Button"])
                            (object ["Cell" "ty14Button"])
                            (object ["Cell" "ui14Button"])
                            (object ["Cell" "op14Button"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "as14Button"])
                            (object ["Cell" "df14Button"])
                            (object ["Cell" "gh14Button"])
                            (object ["Cell" "jk14Button"])
                            (object ["Cell" "l14Button"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "zx14Button"])
                            (object ["Cell" "cv14Button"])
                            (object ["Cell" "bn14Button"])
                            (object ["Cell" "m14Button"])
                            (object ["Cell" "backspaceButton"]))])])
   standard-pinyin-last-row))

(define button-specs
  (list
   (merged18-spec "qw14Button" "q" "QW" "" five-column-size #f #f)
   (merged18-spec "er14Button" "e" "ER" "" five-column-size #f (key-spec-swipe-down (find-hybrid-letter-spec "e")))
   (merged18-spec "ty14Button" "t" "TY" "" five-column-size #f #f)
   (merged18-spec "ui14Button" "u" "UI" "" five-column-size #f #f)
   (merged18-spec "op14Button" "o" "OP" "" five-column-size #f #f)
   (merged18-spec "as14Button" "a" "AS" "" five-column-size #f #f)
   (merged18-spec "df14Button" "d" "DF" "" five-column-size #f #f)
   (merged18-spec "gh14Button" "g" "GH" "" five-column-size #f #f)
   (merged18-spec "jk14Button" "j" "JK" "" five-column-size #f #f)
   (merged18-spec "l14Button" "l" "L" "" five-column-size #f #f)
   (merged18-spec "zx14Button" "z" "ZX" "" five-column-size #f #f)
   (merged18-spec "cv14Button" "c" "CV" "" five-column-size #f #f)
   (merged18-spec "bn14Button" "b" "BN" "" five-column-size #f #f)
   (merged18-spec "m14Button" "m" "M" "" five-column-size #f #f)))

(define third-row-system-size five-column-size)

(define centered-label-center
  (object ["x" (json-number "0.5")]
          ["y" (json-number "0.5")]))

(define (set-entry entry key value)
  (for/list ([pair (in-list entry)])
    (if (equal? (car pair) key)
        (cons key value)
        pair)))

(define (with-14-key-system-sizes page)
  (hash-set page
            "backspaceButton"
            (set-entry (hash-ref page "backspaceButton")
                       "size"
                       third-row-system-size)))

(define (base-page dark? portrait?)
  (with-14-key-system-sizes
   (cond
     [(and (not dark?) portrait?)       flypy18-portrait-light-base]
     [(and dark?       portrait?)       flypy18-portrait-dark-base]
     [(and (not dark?) (not portrait?)) flypy18-landscape-light-base]
     [else                              flypy18-landscape-dark-base])))

(define pinyin-14-iphone-pinyin-files
  (make-flypy18-files
   #:portrait-name   "pinyinPortrait"
   #:landscape-name  "pinyinLandscape"
   #:base-page       base-page
   #:keyboard-layout keyboard-layout
   #:button-specs    button-specs
   #:detail-font-size 10
   #:label-center    centered-label-center))
