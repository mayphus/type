#lang racket/base

(require (except-in "../core/dsl.rkt"
                    button-spec
                    button-spec?
                    make-button)
         "../keysets/pinyin-common.rkt"
         "base-page.rkt"
         "phone-secondary-page.rkt")

(define (symbolic-base dark? portrait?)
  (make-secondary-base-page dark? portrait?
                            #:keyboard-height (if portrait? "216" "160")))

(define symbolic-portrait-light-base  (symbolic-base #f #t))
(define symbolic-portrait-dark-base   (symbolic-base #t #t))
(define symbolic-landscape-light-base (symbolic-base #f #f))
(define symbolic-landscape-dark-base  (symbolic-base #t #f))

(provide symbolic-files)

(define left-offset
  (object ["x" (json-number "0.34999999999999998")]))

(define right-offset
  (object ["x" (json-number "0.65000000000000002")]))

(define keyboard-layout
  (array
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "leftChineseBracketButton"])
                            (object ["Cell" "rightChineseBracketButton"])
                            (object ["Cell" "leftChineseBraceButton"])
                            (object ["Cell" "rightChineseBraceButton"])
                            (object ["Cell" "hashButton"])
                            (object ["Cell" "percentButton"])
                            (object ["Cell" "caretButton"])
                            (object ["Cell" "asteriskButton"])
                            (object ["Cell" "plusButton"])
                            (object ["Cell" "equalButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "underscoreButton"])
                            (object ["Cell" "emDashButton"])
                            (object ["Cell" "backslashButton"])
                            (object ["Cell" "verticalBarButton"])
                            (object ["Cell" "tildeButton"])
                            (object ["Cell" "leftBookTitleMarkButton"])
                            (object ["Cell" "rightBookTitleMarkButton"])
                            (object ["Cell" "graveButton"])
                            (object ["Cell" "ampersandButton"])
                            (object ["Cell" "middleDotButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "numericButton"])
                            (object ["Cell" "ellipsisButton"])
                            (object ["Cell" "commaButton"])
                            (object ["Cell" "periodButton"])
                            (object ["Cell" "questionMarkEnButton"])
                            (object ["Cell" "exclamationMarkButton"])
                            (object ["Cell" "leftSingleQuoteButton"])
                            (object ["Cell" "rightSingleQuoteButton"])
                            (object ["Cell" "backspaceButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "pinyinButton"])
                            (object ["Cell" "spaceButton"])
                            (object ["Cell" "enterButton"]))])])))

(define button-specs
  (list
   (button-spec "leftChineseBracketButton" "【" symbol-action "「" symbol-action left-offset)
   (button-spec "rightChineseBracketButton" "】" symbol-action "」" symbol-action right-offset)
   (button-spec "leftChineseBraceButton" "｛" symbol-action #f #f left-offset)
   (button-spec "rightChineseBraceButton" "｝" symbol-action #f #f right-offset)
   (button-spec "hashButton" "#" symbol-action #f #f #f)
   (button-spec "percentButton" "%" symbol-action #f #f #f)
   (button-spec "caretButton" "^" symbol-action #f #f #f)
   (button-spec "asteriskButton" "*" char-action #f #f #f)
   (button-spec "plusButton" "+" char-action "=" char-action #f)
   (button-spec "equalButton" "=" char-action "+" char-action #f)
   (button-spec "underscoreButton" "_" symbol-action #f #f #f)
   (button-spec "emDashButton" "—" char-action #f #f #f)
   (button-spec "backslashButton" "\\" symbol-action #f #f #f)
   (button-spec "verticalBarButton" "|" symbol-action #f #f #f)
   (button-spec "tildeButton" "~" symbol-action #f #f #f)
   (button-spec "leftBookTitleMarkButton" "《" symbol-action #f #f left-offset)
   (button-spec "rightBookTitleMarkButton" "》" symbol-action #f #f right-offset)
   (button-spec "graveButton" "`" char-action "~" char-action #f)
   (button-spec "ampersandButton" "&" symbol-action #f #f #f)
   (button-spec "middleDotButton" "·" symbol-action #f #f #f)
   (button-spec "ellipsisButton" "…" symbol-action #f #f #f)
   (button-spec "commaButton" "," symbol-action #f #f #f)
   (button-spec "periodButton" "." char-action "," char-action #f)
   (button-spec "questionMarkEnButton" "?" char-action #f #f #f)
   (button-spec "exclamationMarkButton" "!" char-action #f #f #f)
   (button-spec "leftSingleQuoteButton" "‘" symbol-action "“" symbol-action #f)
   (button-spec "rightSingleQuoteButton" "’" symbol-action #f #f #f)))

(define system-button-specs
  (list
   (system-button-spec "numericButton" "123" (keyboard-type-action "numeric") system-width left-system-bounds)
   (system-button-spec "pinyinButton" "拼音" (keyboard-type-action "pinyin") large-system-width #f)))

(define (base-page dark? portrait?)
  (cond
    [(and (not dark?) portrait?) symbolic-portrait-light-base]
    [(and dark? portrait?) symbolic-portrait-dark-base]
    [(and (not dark?) (not portrait?)) symbolic-landscape-light-base]
    [else symbolic-landscape-dark-base]))

(define symbolic-files
  (make-phone-secondary-files
   #:portrait-name "symbolicPortrait"
   #:landscape-name "symbolicLandscape"
   #:base-page base-page
   #:button-specs button-specs
   #:system-buttons system-button-specs
   #:keyboard-layout keyboard-layout))
