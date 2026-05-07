#lang racket/base

(require "../core/dsl.rkt"
         "../keysets/pinyin-common.rkt"
         "flypy18-page.rkt"
         "flypy18-bases.rkt"
         "phone-layout-rows.rkt")

(provide flypy-18-iphone-pinyin-files)

;; Standard Flypy 18-key keyboard layout grid
(define keyboard-layout
  (array
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "q18AltButton"])
                            (object ["Cell" "we18AltButton"])
                            (object ["Cell" "rt18AltButton"])
                            (object ["Cell" "y18AltButton"])
                            (object ["Cell" "u18AltButton"])
                            (object ["Cell" "io18AltButton"])
                            (object ["Cell" "p18AltButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "a18AltButton"])
                            (object ["Cell" "sd18AltButton"])
                            (object ["Cell" "fg18AltButton"])
                            (object ["Cell" "h18AltButton"])
                            (object ["Cell" "jk18AltButton"])
                            (object ["Cell" "l18AltButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "shiftButton"])
                            (object ["Cell" "z18AltButton"])
                            (object ["Cell" "xc18AltButton"])
                            (object ["Cell" "v18AltButton"])
                            (object ["Cell" "bn18AltButton"])
                            (object ["Cell" "m18AltButton"])
                            (object ["Cell" "backspaceButton"]))])])
   standard-pinyin-last-row))

;; Standard Flypy 18-key button specs (7-7-6 row layout with side insets on A and L)
(define button-specs
  (list
   (merged18-spec "q18AltButton"  "q" "Q"  "iu"       seven-column-size #f                    #f)
   (merged18-spec "we18AltButton" "w" "WE" "ei e"     seven-column-size #f                    (key-spec-swipe-down (find-hybrid-letter-spec "e")))
   (merged18-spec "rt18AltButton" "r" "RT" "uan ue"   seven-column-size #f                    #f)
   (merged18-spec "y18AltButton"  "y" "Y"  "un"       seven-column-size #f                    #f)
   (merged18-spec "u18AltButton"  "u" "U"  "sh"       seven-column-size #f                    #f)
   (merged18-spec "io18AltButton" "i" "IO" "ch uo"    seven-column-size #f                    #f)
   (merged18-spec "p18AltButton"  "p" "P"  "ie"       seven-column-size #f                    #f)
   (merged18-spec "a18AltButton"  "a" "A"  "a"        side-inset-size   side-inset-right-bounds #f)
   (merged18-spec "sd18AltButton" "s" "SD" "ong ai"   six-column-size   #f                    #f)
   (merged18-spec "fg18AltButton" "f" "FG" "en eng"   six-column-size   #f                    #f)
   (merged18-spec "h18AltButton"  "h" "H"  "ang"      six-column-size   #f                    #f)
   (merged18-spec "jk18AltButton" "j" "JK" "an ing"   six-column-size   #f                    #f)
   (merged18-spec "l18AltButton"  "l" "L"  "iang uang" side-inset-size  side-inset-left-bounds #f)
   (merged18-spec "z18AltButton"  "z" "Z"  "ou"       seven-column-size #f                    #f)
   (merged18-spec "xc18AltButton" "x" "XC" "ia ao"    seven-column-size #f                    #f)
   (merged18-spec "v18AltButton"  "v" "V"  "zh ui"    seven-column-size #f                    #f)
   (merged18-spec "bn18AltButton" "b" "BN" "in iao"   seven-column-size #f                    #f)
   (merged18-spec "m18AltButton"  "m" "M"  "ian"      seven-column-size #f                    #f)))

(define (base-page dark? portrait?)
  (cond
    [(and (not dark?) portrait?)       flypy18-portrait-light-base]
    [(and dark?       portrait?)       flypy18-portrait-dark-base]
    [(and (not dark?) (not portrait?)) flypy18-landscape-light-base]
    [else                              flypy18-landscape-dark-base]))

(define flypy-18-iphone-pinyin-files
  (make-flypy18-files
   #:portrait-name   "pinyinPortrait"
   #:landscape-name  "pinyinLandscape"
   #:base-page       base-page
   #:keyboard-layout keyboard-layout
   #:button-specs    button-specs
   #:detail-font-size 8))
