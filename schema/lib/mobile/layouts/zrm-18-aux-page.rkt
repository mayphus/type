#lang racket/base

(require "../core/dsl.rkt"
         "../keysets/pinyin-common.rkt"
         "flypy18-page.rkt"
         "flypy18-bases.rkt"
         "phone-layout-rows.rkt")

(provide zrm-18-aux-iphone-pinyin-files)

(define seven-column-size
  (object ["width" "160.7142857143/1125"]))

(define six-column-size
  (object ["width" "160/1125"]))

(define side-inset-size
  (object ["width" "242.5/1125"]))

(define side-inset-right-bounds
  (object ["alignment" "right"]
          ["width" "160/242.5"]))

(define side-inset-left-bounds
  (object ["alignment" "left"]
          ["width" "160/242.5"]))

(define keyboard-layout
  (array
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "q18AuxButton"])
                            (object ["Cell" "we18AuxButton"])
                            (object ["Cell" "rt18AuxButton"])
                            (object ["Cell" "y18AuxButton"])
                            (object ["Cell" "u18AuxButton"])
                            (object ["Cell" "io18AuxButton"])
                            (object ["Cell" "p18AuxButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "a18AuxButton"])
                            (object ["Cell" "sd18AuxButton"])
                            (object ["Cell" "fg18AuxButton"])
                            (object ["Cell" "h18AuxButton"])
                            (object ["Cell" "jk18AuxButton"])
                            (object ["Cell" "l18AuxButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "shiftButton"])
                            (object ["Cell" "z18AuxButton"])
                            (object ["Cell" "xc18AuxButton"])
                            (object ["Cell" "v18AuxButton"])
                            (object ["Cell" "bn18AuxButton"])
                            (object ["Cell" "m18AuxButton"])
                            (object ["Cell" "backspaceButton"]))])])
   standard-pinyin-last-row))

;; Auxiliary legends for ZRM
;; Q: 犭   W: 文   R:    T: 土   Y: 言   I: 厂   P: 丿
;; A: 一   S: 纟   D: 氵   F: 扌   G: 广   H: 禾   J: 金   K: 口   L: 
;; Z: 乙   X: 心   C: 艹   V: 止   B: 宀   N: 女   M: 木
(define button-specs
  (list
   (merged18-spec "q18AuxButton" "q" "Q" "iu 犭" seven-column-size #f #f)
   (merged18-spec "we18AuxButton" "w" "WE" "ia ua e 文" seven-column-size #f (key-spec-swipe-down (find-hybrid-letter-spec "e")))
   (merged18-spec "rt18AuxButton" "r" "RT" "uan ue 土" seven-column-size #f #f)
   (merged18-spec "y18AuxButton" "y" "Y" "ing uai 言" seven-column-size #f #f)
   (merged18-spec "u18AuxButton" "u" "U" "sh 山" seven-column-size #f #f)
   (merged18-spec "io18AuxButton" "i" "IO" "ch uo 厂日" seven-column-size #f #f)
   (merged18-spec "p18AuxButton" "p" "P" "un 丿" seven-column-size #f #f)
   (merged18-spec "a18AuxButton" "a" "A" "a 一" side-inset-size side-inset-right-bounds #f)
   (merged18-spec "sd18AuxButton" "s" "SD" "ong ai 纟氵" six-column-size #f #f)
   (merged18-spec "fg18AuxButton" "f" "FG" "en eng 扌广" six-column-size #f #f)
   (merged18-spec "h18AuxButton" "h" "H" "ang 禾" six-column-size #f #f)
   (merged18-spec "jk18AuxButton" "j" "JK" "an ao 金口" six-column-size #f #f)
   (merged18-spec "l18AuxButton" "l" "L" "iang uang" side-inset-size side-inset-left-bounds #f)
   (merged18-spec "z18AuxButton" "z" "Z" "ei 乙" seven-column-size #f #f)
   (merged18-spec "xc18AuxButton" "x" "XC" "ie iao 心艹" seven-column-size #f #f)
   (merged18-spec "v18AuxButton" "v" "V" "zh ui 止" seven-column-size #f #f)
   (merged18-spec "bn18AuxButton" "b" "BN" "ou in 宀女" seven-column-size #f #f)
   (merged18-spec "m18AuxButton" "m" "M" "ian 木" seven-column-size #f #f)))

(define (base-page dark? portrait?)
  (cond
    [(and (not dark?) portrait?) flypy18-portrait-light-base]
    [(and dark? portrait?) flypy18-portrait-dark-base]
    [(and (not dark?) (not portrait?)) flypy18-landscape-light-base]
    [else flypy18-landscape-dark-base]))

(define zrm-18-aux-iphone-pinyin-files
  (make-flypy18-files
   #:portrait-name "pinyinPortrait"
   #:landscape-name "pinyinLandscape"
   #:base-page base-page
   #:keyboard-layout keyboard-layout
   #:button-specs button-specs
   #:detail-font-size 7))
