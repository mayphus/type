#lang racket/base

(require racket/hash
         "base-page.rkt"
         "../core/dsl.rkt"
         "../keysets/pinyin-common.rkt")

(provide standard-ipad-numeric-files)

(define normal-button-size
  (object ["width" "1.1/16"]))

(define first-row-style
  (hash
   "firstRowStyle"
   (object ["size" (object ["height" (json-number "55")])])))

(define first-row-style-landscape
  (hash
   "firstRowStyle"
   (object ["size" (object ["height" (json-number "70")])])))

(define left-system-offset
  (object ["x" (json-number "0.25")]
          ["y" (json-number "0.59999999999999998")]))

(define right-system-offset
  (object ["x" (json-number "0.75")]
          ["y" (json-number "0.59999999999999998")]))

(define compact-center
  (object ["y" (json-number "0.65000000000000002")]))

(define keyboard-layout
  (array
   (object ["HStack"
            (object ["style" "firstRowStyle"]
                    ["subviews"
                     (array (object ["Cell" "periodButton"])
                            (object ["Cell" "oneButton"])
                            (object ["Cell" "twoButton"])
                            (object ["Cell" "threeButton"])
                            (object ["Cell" "fourButton"])
                            (object ["Cell" "fiveButton"])
                            (object ["Cell" "sixButton"])
                            (object ["Cell" "sevenButton"])
                            (object ["Cell" "eightButton"])
                            (object ["Cell" "nineButton"])
                            (object ["Cell" "zeroButton"])
                            (object ["Cell" "lessThanButton"])
                            (object ["Cell" "greaterThanButton"])
                            (object ["Cell" "backspaceButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "tabButton"])
                            (object ["Cell" "leftChineseBracketButton"])
                            (object ["Cell" "rightChineseBracketButton"])
                            (object ["Cell" "leftChineseBraceButton"])
                            (object ["Cell" "rightChineseBraceButton"])
                            (object ["Cell" "hashButton"])
                            (object ["Cell" "percentButton"])
                            (object ["Cell" "caretButton"])
                            (object ["Cell" "asteriskButton"])
                            (object ["Cell" "plusButton"])
                            (object ["Cell" "equalButton"])
                            (object ["Cell" "backslashButton"])
                            (object ["Cell" "verticalBarButton"])
                            (object ["Cell" "underscoreButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "asciiModeButton"])
                            (object ["Cell" "hyphenButton"])
                            (object ["Cell" "forwardSlashButton"])
                            (object ["Cell" "chineseColonButton"])
                            (object ["Cell" "chineseSemicolonButton"])
                            (object ["Cell" "leftChineseParenthesisButton"])
                            (object ["Cell" "rightChineseParenthesisButton"])
                            (object ["Cell" "dollarButton"])
                            (object ["Cell" "ampersandButton"])
                            (object ["Cell" "atButton"])
                            (object ["Cell" "leftSingleQuoteButton"])
                            (object ["Cell" "euroButton"])
                            (object ["Cell" "enterButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "leftshiftButton"])
                            (object ["Cell" "ellipsisButton"])
                            (object ["Cell" "middleDotButton"])
                            (object ["Cell" "chinesePeriodButton"])
                            (object ["Cell" "chineseCommaButton"])
                            (object ["Cell" "ideographicCommaButton"])
                            (object ["Cell" "questionMarkButton"])
                            (object ["Cell" "chineseExclamationMarkButton"])
                            (object ["Cell" "tildeButton"])
                            (object ["Cell" "leftCurlyQuoteButton"])
                            (object ["Cell" "rightCurlyQuoteButton"])
                            (object ["Cell" "rightshiftButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "otherKeyboardButton"])
                            (object ["Cell" "pinyinButton"])
                            (object ["Cell" "spaceButton"])
                            (object ["Cell" "pinyinButton"])
                            (object ["Cell" "dismissButton"]))])])))

(define simple-button-specs
  (list
   (list "periodButton" "." char-action "," char-action 22.5 #f)
   (list "oneButton" "1" char-action "!" char-action 22.5 #f)
   (list "twoButton" "2" char-action "@" char-action 22.5 #f)
   (list "threeButton" "3" char-action "#" char-action 22.5 #f)
   (list "fourButton" "4" char-action "$" char-action 22.5 #f)
   (list "fiveButton" "5" char-action "%" char-action 22.5 #f)
   (list "sixButton" "6" char-action "^" char-action 22.5 #f)
   (list "sevenButton" "7" char-action "&" char-action 22.5 #f)
   (list "eightButton" "8" char-action "*" char-action 22.5 #f)
   (list "nineButton" "9" char-action "(" char-action 22.5 #f)
   (list "zeroButton" "0" char-action ")" char-action 22.5 #f)
   (list "lessThanButton" "<" symbol-action #f #f 22.5 #f)
   (list "greaterThanButton" ">" symbol-action #f #f 22.5 #f)
   (list "leftChineseBracketButton" "【" symbol-action "「" symbol-action 22.5 #f)
   (list "rightChineseBracketButton" "】" symbol-action "」" symbol-action 22.5 #f)
   (list "leftChineseBraceButton" "｛" symbol-action #f #f 22.5 #f)
   (list "rightChineseBraceButton" "｝" symbol-action #f #f 22.5 #f)
   (list "hashButton" "#" symbol-action #f #f 22.5 #f)
   (list "percentButton" "%" symbol-action #f #f 22.5 #f)
   (list "caretButton" "^" symbol-action #f #f 22.5 #f)
   (list "asteriskButton" "*" char-action #f #f 22.5 #f)
   (list "plusButton" "+" char-action "=" char-action 22.5 #f)
   (list "equalButton" "=" char-action "+" char-action 22.5 #f)
   (list "backslashButton" "\\" symbol-action #f #f 22.5 #f)
   (list "verticalBarButton" "|" symbol-action #f #f 22.5 #f)
   (list "underscoreButton" "_" symbol-action #f #f 22.5 #f)
   (list "hyphenButton" "-" char-action "——" char-action 22.5 #f)
   (list "forwardSlashButton" "/" char-action "?" char-action 22.5 #f)
   (list "chineseColonButton" "：" symbol-action #f #f 22.5 #f)
   (list "chineseSemicolonButton" "；" symbol-action "：" symbol-action 22.5 #f)
   (list "leftChineseParenthesisButton" "（" symbol-action #f #f 22.5 #f)
   (list "rightChineseParenthesisButton" "）" symbol-action #f #f 22.5 #f)
   (list "dollarButton" "$" symbol-action #f #f 22.5 #f)
   (list "ampersandButton" "&" symbol-action #f #f 22.5 #f)
   (list "atButton" "@" symbol-action #f #f 22.5 #f)
   (list "leftSingleQuoteButton" "‘" symbol-action "“" symbol-action 14 compact-center)
   (list "euroButton" "€" symbol-action #f #f 22.5 #f)
   (list "ellipsisButton" "…" symbol-action #f #f 22.5 #f)
   (list "middleDotButton" "·" symbol-action #f #f 22.5 #f)
   (list "chinesePeriodButton" "。" symbol-action "》" symbol-action 22.5 #f)
   (list "chineseCommaButton" "，" symbol-action "《" symbol-action 22.5 #f)
   (list "ideographicCommaButton" "、" symbol-action "|" symbol-action 22.5 #f)
   (list "questionMarkButton" "？" symbol-action #f #f 22.5 #f)
   (list "chineseExclamationMarkButton" "！" symbol-action #f #f 22.5 #f)
   (list "tildeButton" "~" symbol-action #f #f 14 compact-center)
   (list "leftCurlyQuoteButton" "“" symbol-action #f #f 14 compact-center)
   (list "rightCurlyQuoteButton" "”" symbol-action #f #f 14 compact-center)))

(define (simple-button-entry dark? spec)
  (define name (list-ref spec 0))
  (define text (list-ref spec 1))
  (define action-proc (list-ref spec 2))
  (define swipe-up (list-ref spec 3))
  (define swipe-up-proc (list-ref spec 4))
  (define font-size (list-ref spec 5))
  (define center (list-ref spec 6))
  (hash
   name
   (append
    (list (cons "action" (action-proc text))
          (cons "backgroundStyle" "alphabeticButtonBackgroundStyle")
          (cons "foregroundStyle" (string-append name "ForegroundStyle"))
          (cons "hintStyle" (string-append name "HintStyle"))
          (cons "size" normal-button-size))
    (if swipe-up
        (list (cons "swipeUpAction" (swipe-up-proc swipe-up)))
        '()))
   (string-append name "ForegroundStyle")
   (text-foreground-style dark?
                          text
                          #:font-size font-size
                          #:center center)
   (string-append name "HintForegroundStyle")
   (object ["buttonStyleType" "text"]
           ["fontSize" (json-number "26")]
           ["normalColor" (theme-primary dark?)]
           ["text" text])
   (string-append name "HintStyle")
   (object ["backgroundStyle" "alphabeticHintBackgroundStyle"]
           ["foregroundStyle" (string-append name "HintForegroundStyle")])))

(define (image-system-button/center dark? name action width image-name center #:highlight-image [highlight-image #f])
  (hash
   name
   (object ["action" action]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" (string-append name "ForegroundStyle")]
           ["size" (object ["width" width])])
   (string-append name "ForegroundStyle")
   (append
    (system-image-style dark? image-name #:highlight-image highlight-image)
    (list (cons "center" center)))))

(define (image-system-button dark? name action width image-name)
  (hash
   name
   (object ["action" action]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" (string-append name "ForegroundStyle")]
           ["size" (object ["width" width])])
   (string-append name "ForegroundStyle")
   (system-image-style dark? image-name)))

(define (text-system-button dark? name action width text)
  (hash
   name
   (object ["action" action]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" (string-append name "ForegroundStyle")]
           ["size" (object ["width" width])])
   (string-append name "ForegroundStyle")
   (text-foreground-style dark? text)))

(define enter-background-style
  (array
   (object ["conditionKey" "$returnKeyType"]
           ["conditionValue" (array 0 2 3 5 6 8 11)]
           ["styleName" "systemButtonBackgroundStyle"])
   (object ["conditionKey" "$returnKeyType"]
           ["conditionValue" (array 1 4 7 9 10)]
           ["styleName" "blueButtonBackgroundStyle"])))

(define enter-foreground-style
  (array
   (object ["conditionKey" "$returnKeyType"]
           ["conditionValue" (array 0 2 3 5 6 8 11)]
           ["styleName" "enterButtonForegroundStyle"])
   (object ["conditionKey" "$returnKeyType"]
           ["conditionValue" (array 1 4 7 9 10)]
           ["styleName" "blueButtonForegroundStyle"])))

(define (enter-button dark?)
  (hash
   "enterButton"
   (object ["action" "enter"]
           ["backgroundStyle" enter-background-style]
           ["foregroundStyle" enter-foreground-style]
           ["notification" (array "returnKeyTypeChangedNotification"
                                  "preeditChangedForEnterButtonNotification")]
           ["size" (object ["width" "3.9/32"])])
   "enterButtonForegroundStyle"
   (text-foreground-style dark? "$returnKeyType")))

(define (shift-buttons dark?)
  (hash
   "leftshiftButton"
   (object ["action" "shift"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["capsLockedStateForegroundStyle" "shiftButtonCapsLockedForegroundStyle"]
           ["foregroundStyle" "leftshiftButtonForegroundStyle"]
           ["size" (object ["width" "2.5/16"])]
           ["uppercasedStateForegroundStyle" "shiftButtonUppercasedForegroundStyle"])
   "leftshiftButtonForegroundStyle"
   (system-image-style dark? "shift")
   "rightshiftButton"
   (object ["action" "shift"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["capsLockedStateForegroundStyle" "shiftButtonCapsLockedForegroundStyle"]
           ["foregroundStyle" "rightshiftButtonForegroundStyle"]
           ["size" (object ["width" "2.5/16"])]
           ["uppercasedStateForegroundStyle" "shiftButtonUppercasedForegroundStyle"])
   "rightshiftButtonForegroundStyle"
   (system-image-style dark? "shift")
   "shiftButtonCapsLockedForegroundStyle"
   (system-image-style dark? "capslock.fill")
   "shiftButtonUppercasedForegroundStyle"
   (system-image-style dark? "shift.fill")))

(define (space-button dark?)
  (hash
   "spaceButton"
   (object ["action" "space"]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" "spaceButtonForegroundStyle"]
           ["notification" (array "preeditChangedForSpaceButtonNotification")]
           ["swipeUpAction" (shortcut-action "#次选上屏")])
   "spaceButtonForegroundStyle"
   (system-image-style dark? "space")))

(define (non-letter-entries dark? portrait?)
  (bundle
   (if portrait? first-row-style first-row-style-landscape)
   (hash "keyboardLayout" keyboard-layout)
   (apply bundle
          (for/list ([spec (in-list simple-button-specs)])
            (simple-button-entry dark? spec)))
   (text-system-button dark? "asciiModeButton" (shortcut-action "#中英切换") "3.9/32" "中/英")
   (image-system-button/center dark? "tabButton" "tab" "1.7/16" "arrow.right.to.line" left-system-offset)
   (image-system-button/center dark? "backspaceButton" "backspace" "1.7/16" "delete.left" right-system-offset #:highlight-image "delete.left.fill")
   (image-system-button dark? "otherKeyboardButton" "nextKeyboard" "1.65/16" "globe")
   (text-system-button dark? "pinyinButton" (keyboard-type-action "pinyin") "1.65/16" "拼音")
   (image-system-button dark? "dismissButton" "dismissKeyboard" "1.65/16" "keyboard.chevron.compact.down")
   (shift-buttons dark?)
   (space-button dark?)
   (enter-button dark?)))

(define (ordered-page dark? portrait?)
  (define combined
    (hash-union
     (make-ipad-base-page dark? portrait?
                          #:keyboard-height (if portrait? "311" "414"))
     (non-letter-entries dark? portrait?)
     #:combine/key (lambda (_ left _right) left)))
  (auto-ordered-page combined))

(define standard-ipad-numeric-files
  (bundle
   (json-file (yaml-page "light" "iPadNumericPortrait")
              (ordered-page #f #t))
   (json-file (yaml-page "dark" "iPadNumericPortrait")
              (ordered-page #t #t))
   (json-file (yaml-page "light" "iPadNumericLandscape")
              (ordered-page #f #f))
   (json-file (yaml-page "dark" "iPadNumericLandscape")
              (ordered-page #t #f))))
