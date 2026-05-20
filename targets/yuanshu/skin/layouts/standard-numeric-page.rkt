#lang racket/base

(require (except-in "../core/dsl.rkt"
                    button-spec
                    button-spec?
                    make-button)
         "../keysets/pinyin-common.rkt"
         "base-page.rkt"
         "phone-secondary-page.rkt")

(define (numeric-base dark? portrait?)
  (make-secondary-base-page dark? portrait?
                            #:keyboard-height (if portrait? "216" "160")))

(define numeric-portrait-light-base  (numeric-base #f #t))
(define numeric-portrait-dark-base   (numeric-base #t #t))
(define numeric-landscape-light-base (numeric-base #f #f))
(define numeric-landscape-dark-base  (numeric-base #t #f))

(provide numeric-files)

(define chinese-symbolic-center
  (object ["x" (json-number "0.55000000000000004")]))

(define keyboard-layout
  (array
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "oneButton"])
                            (object ["Cell" "twoButton"])
                            (object ["Cell" "threeButton"])
                            (object ["Cell" "fourButton"])
                            (object ["Cell" "fiveButton"])
                            (object ["Cell" "sixButton"])
                            (object ["Cell" "sevenButton"])
                            (object ["Cell" "eightButton"])
                            (object ["Cell" "nineButton"])
                            (object ["Cell" "zeroButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "hyphenButton"])
                            (object ["Cell" "forwardSlashButton"])
                            (object ["Cell" "colonButton"])
                            (object ["Cell" "semicolonButton"])
                            (object ["Cell" "leftParenthesisButton"])
                            (object ["Cell" "rightParenthesisButton"])
                            (object ["Cell" "dollarButton"])
                            (object ["Cell" "atButton"])
                            (object ["Cell" "leftCurlyQuoteButton"])
                            (object ["Cell" "rightCurlyQuoteButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "symbolicButton"])
                            (object ["Cell" "chinesePeriodButton"])
                            (object ["Cell" "chineseCommaButton"])
                            (object ["Cell" "ideographicCommaButton"])
                            (object ["Cell" "hashButton"])
                            (object ["Cell" "questionMarkEnButton"])
                            (object ["Cell" "exclamationMarkButton"])
                            (object ["Cell" "periodButton"])
                            (object ["Cell" "backspaceButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "pinyinButton"])
                            (object ["Cell" "spaceButton"])
                            (object ["Cell" "enterButton"]))])])))

(define button-specs
  (list
   (button-spec "oneButton" "1" char-action "!" char-action #f)
   (button-spec "twoButton" "2" char-action "@" char-action #f)
   (button-spec "threeButton" "3" char-action "#" char-action #f)
   (button-spec "fourButton" "4" char-action "$" char-action #f)
   (button-spec "fiveButton" "5" char-action "%" char-action #f)
   (button-spec "sixButton" "6" char-action "^" char-action #f)
   (button-spec "sevenButton" "7" char-action "&" char-action #f)
   (button-spec "eightButton" "8" char-action "*" char-action #f)
   (button-spec "nineButton" "9" char-action "(" char-action #f)
   (button-spec "zeroButton" "0" char-action ")" char-action #f)
   (button-spec "hyphenButton" "-" char-action "——" char-action #f)
   (button-spec "forwardSlashButton" "/" char-action "?" char-action #f)
   (button-spec "colonButton" ":" char-action #f #f #f)
   (button-spec "semicolonButton" ";" char-action #f #f #f)
   (button-spec "leftParenthesisButton" "(" symbol-action #f #f #f)
   (button-spec "rightParenthesisButton" ")" symbol-action #f #f #f)
   (button-spec "dollarButton" "$" symbol-action #f #f #f)
   (button-spec "atButton" "@" symbol-action #f #f #f)
   (button-spec "leftCurlyQuoteButton" "“" symbol-action #f #f #f)
   (button-spec "rightCurlyQuoteButton" "”" symbol-action #f #f #f)
   (button-spec "questionMarkEnButton" "?" char-action #f #f #f)
   (button-spec "exclamationMarkButton" "!" char-action #f #f #f)
   (button-spec "hashButton" "#" symbol-action #f #f #f)
   (button-spec "ideographicCommaButton" "、" symbol-action "|" symbol-action chinese-symbolic-center)
   (button-spec "chineseCommaButton" "，" symbol-action "《" symbol-action chinese-symbolic-center)
   (button-spec "chinesePeriodButton" "。" symbol-action "》" symbol-action chinese-symbolic-center)
   (button-spec "periodButton" "." char-action "," char-action #f)))

(define system-button-specs
  (list
   (system-button-spec "symbolicButton" "#+=" (keyboard-type-action "symbolic") system-width left-system-bounds)
   (system-button-spec "pinyinButton" "拼音" (keyboard-type-action "pinyin") large-system-width #f)))

(define (base-page dark? portrait?)
  (cond
    [(and (not dark?) portrait?) numeric-portrait-light-base]
    [(and dark? portrait?) numeric-portrait-dark-base]
    [(and (not dark?) (not portrait?)) numeric-landscape-light-base]
    [else numeric-landscape-dark-base]))

(define numeric-files
  (make-phone-secondary-files
   #:portrait-name "numericPortrait"
   #:landscape-name "numericLandscape"
   #:base-page base-page
   #:button-specs button-specs
   #:system-buttons system-button-specs
   #:keyboard-layout keyboard-layout))
