#lang racket/base

(require racket/hash
         "../core/dsl.rkt"
         "../keysets/pinyin-common.rkt"
         "flypy18-page.rkt"
         "flypy18-bases.rkt")

(provide pinyin-14-iphone-pinyin-files)

(define five-column-size
  (object ["width" "225/1125"]))

(define third-row-spacer-size
  (object ["width" "82.5/1125"]))

(define third-row-spacer-entries
  (hash "thirdRowLeftSpacer"
        (object ["size" third-row-spacer-size])
        "thirdRowRightSpacer"
        (object ["size" third-row-spacer-size])))

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
                     (array (object ["Cell" "thirdRowLeftSpacer"])
                            (object ["Cell" "shiftButton"])
                            (object ["Cell" "zx14Button"])
                            (object ["Cell" "cv14Button"])
                            (object ["Cell" "bn14Button"])
                            (object ["Cell" "m14Button"])
                            (object ["Cell" "backspaceButton"])
                            (object ["Cell" "thirdRowRightSpacer"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "numericButton"])
                            (object ["Cell" "emojiButton"])
                            (object ["Cell" "spaceButton"])
                            (object ["Cell" "semicolonButton"])
                            (object ["Cell" "enterButton"]))])])))

(define button-specs
  (list
   (merged18-spec "qw14Button" "q" "QW" "q w" five-column-size #f #f)
   (merged18-spec "er14Button" "e" "ER" "e r" five-column-size #f (key-spec-swipe-down (find-hybrid-letter-spec "e")))
   (merged18-spec "ty14Button" "t" "TY" "t y" five-column-size #f #f)
   (merged18-spec "ui14Button" "u" "UI" "u i" five-column-size #f #f)
   (merged18-spec "op14Button" "o" "OP" "o p" five-column-size #f #f)
   (merged18-spec "as14Button" "a" "AS" "a s" five-column-size #f #f)
   (merged18-spec "df14Button" "d" "DF" "d f" five-column-size #f #f)
   (merged18-spec "gh14Button" "g" "GH" "g h" five-column-size #f #f)
   (merged18-spec "jk14Button" "j" "JK" "j k" five-column-size #f #f)
   (merged18-spec "l14Button" "l" "L" "l" five-column-size #f #f)
   (merged18-spec "zx14Button" "z" "ZX" "z x" six-column-size #f #f)
   (merged18-spec "cv14Button" "c" "CV" "c v" six-column-size #f #f)
   (merged18-spec "bn14Button" "b" "BN" "b n" six-column-size #f #f)
   (merged18-spec "m14Button" "m" "M" "m" six-column-size #f #f)))

(define third-row-system-size six-column-size)

(define (set-entry entry key value)
  (for/list ([pair (in-list entry)])
    (if (equal? (car pair) key)
        (cons key value)
        pair)))

(define (with-14-key-system-sizes page)
  (hash-union
   (hash-set* page
              "shiftButton"
              (set-entry (hash-ref page "shiftButton")
                         "size"
                         third-row-system-size)
              "backspaceButton"
              (set-entry (hash-ref page "backspaceButton")
                         "size"
                         third-row-system-size))
   third-row-spacer-entries
   #:combine/key (lambda (_ _left right) right)))

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
   #:detail-font-size 10))
