#lang racket/base

(require racket/hash
         racket/list
         "base-page.rkt"
         "../core/dsl.rkt"
         "../keysets/pinyin-common.rkt")

(provide make-standard-ipad-pinyin-files
         ipad-letter-config
         ipad-pinyin-files)

(define normal-button-size
  (object ["width" "1.1/16"]))

(define top-center
  (object ["y" (json-number "0.29999999999999999")]))

(define bottom-center
  (object ["y" (json-number "0.65000000000000002")]))

(define left-system-offset
  (object ["x" (json-number "0.25")]
          ["y" (json-number "0.59999999999999998")]))

(define right-system-offset
  (object ["x" (json-number "0.75")]
          ["y" (json-number "0.59999999999999998")]))

(define first-row-style
  (hash
   "firstRowStyle"
   (object ["size" (object ["height" (json-number "55")])])))

(define first-row-style-landscape
  (hash
   "firstRowStyle"
   (object ["size" (object ["height" (json-number "70")])])))

(define keyboard-layout
  (array
   (object ["HStack"
            (object ["style" "firstRowStyle"]
                    ["subviews"
                     (array (object ["Cell" "graveButton"])
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
                            (object ["Cell" "hyphenButton"])
                            (object ["Cell" "equalButton"])
                            (object ["Cell" "backspaceButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "tabButton"])
                            (object ["Cell" "qButton"])
                            (object ["Cell" "wButton"])
                            (object ["Cell" "eButton"])
                            (object ["Cell" "rButton"])
                            (object ["Cell" "tButton"])
                            (object ["Cell" "yButton"])
                            (object ["Cell" "uButton"])
                            (object ["Cell" "iButton"])
                            (object ["Cell" "oButton"])
                            (object ["Cell" "pButton"])
                            (object ["Cell" "leftChineseBracketButton"])
                            (object ["Cell" "rightChineseBracketButton"])
                            (object ["Cell" "ideographicCommaButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "asciiModeButton"])
                            (object ["Cell" "aButton"])
                            (object ["Cell" "sButton"])
                            (object ["Cell" "dButton"])
                            (object ["Cell" "fButton"])
                            (object ["Cell" "gButton"])
                            (object ["Cell" "hButton"])
                            (object ["Cell" "jButton"])
                            (object ["Cell" "kButton"])
                            (object ["Cell" "lButton"])
                            (object ["Cell" "chineseSemicolonButton"])
                            (object ["Cell" "leftSingleQuoteButton"])
                            (object ["Cell" "enterButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "leftshiftButton"])
                            (object ["Cell" "zButton"])
                            (object ["Cell" "xButton"])
                            (object ["Cell" "cButton"])
                            (object ["Cell" "vButton"])
                            (object ["Cell" "bButton"])
                            (object ["Cell" "nButton"])
                            (object ["Cell" "mButton"])
                            (object ["Cell" "chineseCommaButton"])
                            (object ["Cell" "chinesePeriodButton"])
                            (object ["Cell" "forwardSlashButton"])
                            (object ["Cell" "rightshiftButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "otherKeyboardButton"])
                            (object ["Cell" "numericButton"])
                            (object ["Cell" "spaceButton"])
                            (object ["Cell" "numericButton"])
                            (object ["Cell" "dismissButton"]))])])))

(define dual-label-specs
  (list
   (list "graveButton" "`" char-action "~" char-action "tildeButtonForegroundStyle")
   (list "oneButton" "1" char-action "!" char-action "exclamationMarkButtonForegroundStyle")
   (list "twoButton" "2" char-action "@" char-action "atButtonForegroundStyle")
   (list "threeButton" "3" char-action "#" char-action "hashButtonForegroundStyle")
   (list "fourButton" "4" char-action "$" char-action "dollarButtonForegroundStyle")
   (list "fiveButton" "5" char-action "%" char-action "percentButtonForegroundStyle")
   (list "sixButton" "6" char-action "^" char-action "caretButtonForegroundStyle")
   (list "sevenButton" "7" char-action "&" char-action "ampersandButtonForegroundStyle")
   (list "eightButton" "8" char-action "*" char-action "asteriskButtonForegroundStyle")
   (list "nineButton" "9" char-action "(" char-action "leftParenthesisButtonForegroundStyle")
   (list "zeroButton" "0" char-action ")" char-action "rightParenthesisButtonForegroundStyle")
   (list "hyphenButton" "-" char-action "——" char-action "emDashButtonForegroundStyle")
   (list "equalButton" "=" char-action "+" char-action "plusButtonForegroundStyle")
   (list "leftChineseBracketButton" "【" symbol-action "「" symbol-action "leftChineseAngleQuoteButtonForegroundStyle")
   (list "rightChineseBracketButton" "】" symbol-action "」" symbol-action "rightChineseAngleQuoteButtonForegroundStyle")
   (list "ideographicCommaButton" "、" symbol-action "|" symbol-action "verticalBarButtonForegroundStyle")
   (list "chineseSemicolonButton" "；" symbol-action "：" symbol-action "chineseColonButtonForegroundStyle")
   (list "leftSingleQuoteButton" "’" symbol-action "”" symbol-action "rightCurlyQuoteButtonForegroundStyle")
   (list "chineseCommaButton" "，" symbol-action "《" symbol-action "leftBookTitleMarkButtonForegroundStyle")
   (list "chinesePeriodButton" "。" symbol-action "》" symbol-action "rightBookTitleMarkButtonForegroundStyle")
   (list "forwardSlashButton" "/" char-action "?" char-action "questionMarkEnButtonForegroundStyle")))

(define (dual-button-entry dark? spec)
  (define name (list-ref spec 0))
  (define base-text (list-ref spec 1))
  (define base-action (list-ref spec 2))
  (define top-text (list-ref spec 3))
  (define top-action (list-ref spec 4))
  (define top-style-name (list-ref spec 5))
  (hash
   name
   (object ["action" (base-action base-text)]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" (array top-style-name (string-append name "ForegroundStyle"))]
           ["hintStyle" (string-append name "HintStyle")]
           ["size" normal-button-size]
           ["swipeUpAction" (top-action top-text)])
   (string-append name "ForegroundStyle")
   (text-foreground-style dark? base-text #:font-size (json-number "14") #:center bottom-center)
   (string-append name "HintForegroundStyle")
   (text-foreground-style dark? base-text #:font-size (json-number "26") #:highlight-color (theme-primary dark?))
   (string-append name "HintStyle")
   (object ["backgroundStyle" "alphabeticHintBackgroundStyle"]
           ["foregroundStyle" (string-append name "HintForegroundStyle")])))

(define top-style-specs
  (list
   (list "tildeButtonForegroundStyle" "~")
   (list "exclamationMarkButtonForegroundStyle" "!")
   (list "atButtonForegroundStyle" "@")
   (list "hashButtonForegroundStyle" "#")
   (list "dollarButtonForegroundStyle" "$")
   (list "percentButtonForegroundStyle" "%")
   (list "caretButtonForegroundStyle" "^")
   (list "ampersandButtonForegroundStyle" "&")
   (list "asteriskButtonForegroundStyle" "*")
   (list "leftParenthesisButtonForegroundStyle" "(")
   (list "rightParenthesisButtonForegroundStyle" ")")
   (list "emDashButtonForegroundStyle" "—")
   (list "plusButtonForegroundStyle" "+")
   (list "leftChineseAngleQuoteButtonForegroundStyle" "「")
   (list "rightChineseAngleQuoteButtonForegroundStyle" "」")
   (list "verticalBarButtonForegroundStyle" "|")
   (list "chineseColonButtonForegroundStyle" "：")
   (list "rightCurlyQuoteButtonForegroundStyle" "”")
   (list "leftBookTitleMarkButtonForegroundStyle" "《")
   (list "rightBookTitleMarkButtonForegroundStyle" "》")
   (list "questionMarkEnButtonForegroundStyle" "?")))

(define (top-style-entries dark?)
  (for/fold ([acc (hash)]) ([spec (in-list top-style-specs)])
    (hash-set acc
              (car spec)
              (text-foreground-style dark? (cadr spec) #:font-size (json-number "14") #:center top-center))))

(define (system-button dark? name action width foreground-style)
  (hash
   name
   (object ["action" action]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" (string-append name "ForegroundStyle")]
           ["size" (object ["width" width])])
   (string-append name "ForegroundStyle")
   foreground-style))

(define (image-system-button dark? name action width image-name #:center [center #f] #:highlight-image [highlight-image #f])
  (system-button dark?
                 name
                 action
                 width
                 (system-image-style dark? image-name
                                     #:highlight-image highlight-image)))

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

(define (text-system-button dark? name action width text)
  (system-button dark?
                 name
                 action
                 width
                 (text-foreground-style dark? text)))

(define (space-button dark?)
  (hash
   "spaceButton"
   (object ["action" "space"]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" "spaceButtonForegroundStyle"]
           ["notification" (array "preeditChangedForSpaceButtonNotification")]
           ["swipeUpAction" (object ["shortcut" "#次选上屏"])])
   "spaceButtonForegroundStyle"
   (system-image-style dark? "space")))

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

(define (standard-system-entries dark?)
  (bundle
   (text-system-button dark? "asciiModeButton" (shortcut-action "#中英切换") "3.9/32" "中/英")
   (image-system-button/center dark? "tabButton" "tab" "1.7/16" "arrow.right.to.line" left-system-offset)
   (image-system-button/center dark? "backspaceButton" "backspace" "1.7/16" "delete.left" right-system-offset #:highlight-image "delete.left.fill")
   (text-system-button dark? "numericButton" (keyboard-type-action "numeric") "1.65/16" "123")
   (image-system-button dark? "otherKeyboardButton" "nextKeyboard" "1.65/16" "globe")
   (image-system-button dark? "dismissButton" "dismissKeyboard" "1.65/16" "keyboard.chevron.compact.down")
   (space-button dark?)
   (enter-button dark?)
   (shift-buttons dark?)))

(define (non-letter-entries dark? portrait?)
  (bundle
   (if portrait? first-row-style first-row-style-landscape)
   (hash "keyboardLayout" keyboard-layout)
   (top-style-entries dark?)
   (apply bundle
          (for/list ([spec (in-list dual-label-specs)])
            (dual-button-entry dark? spec)))
   (standard-system-entries dark?)))

(define (ordered-page dark? portrait? letter-builder)
  (define combined
    (hash-union
     (make-ipad-base-page dark? portrait?
                          #:keyboard-height (if portrait? "311" "414"))
     (non-letter-entries dark? portrait?)
     (letter-builder dark?)
     #:combine/key (lambda (_ left _right) left)))
  (auto-ordered-page combined))

(define (make-standard-ipad-pinyin-files
         #:portrait-name [portrait-name "iPadPinyinPortrait"]
         #:landscape-name [landscape-name "iPadPinyinLandscape"]
         #:letter-specs [letter-specs hybrid-letter-specs]
         #:letter-config letter-config)
  (define (letter-builder dark?)
    (make-letter-entry-hash dark? letter-specs letter-config))
  (bundle
   (json-file (yaml-page "light" portrait-name)
              (ordered-page #f #t letter-builder))
   (json-file (yaml-page "dark" portrait-name)
              (ordered-page #t #t letter-builder))
   (json-file (yaml-page "light" landscape-name)
              (ordered-page #f #f letter-builder))
   (json-file (yaml-page "dark" landscape-name)
              (ordered-page #t #f letter-builder))))

;; Default standard-18 iPad config and prebuilt bundle
(define ipad-letter-config
  (hash
   'size-for (lambda (_spec) (values normal-button-size #f '()))
   'abc-font-size 12
   'cangjie-font-size 18
   'symbol-font-size 10
   'flypy-single-font-size (json-number "16.5")
   'flypy-double-font-size (json-number "11.5")
   'hint-style-extra '()))

(define ipad-pinyin-files
  (make-standard-ipad-pinyin-files
   #:letter-config ipad-letter-config))
