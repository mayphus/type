#lang racket/base

(require racket/hash
         racket/list
         racket/string
         "base-page.rkt"
         "../core/dsl.rkt"
         "../keysets/pinyin-common.rkt")

(provide soft46-config-data
         soft46-pinyin-files)

(struct phone-key-spec
  (name action hint-text swipe-up swipe-down badge? uppercase-text size primary-style)
  #:transparent)

(define soft46-config-data
  (object
   ["pinyin"
    (object
     ["iPad"
      (object
       ["floating" "pinyinPortrait"]
       ["landscape" "iPadPinyinLandscape"]
       ["portrait" "iPadPinyinPortrait"])]
     ["iPhone"
      (object
       ["landscape" "pinyinLandscape"]
       ["portrait" "pinyinPortrait"])])]))

(define hint-size
  (object ["height" 50]
          ["width" 50]))

(define portrait-system-width
  (object ["width" "168.75/1125"]))

(define portrait-apostrophe-width
  (object ["width" "112.5/1125"]))

(define landscape-numeric-width
  (object ["width" "90/1125"]))

(define landscape-small-width
  (object ["width" "78.75/1125"]))

(define landscape-backspace-width
  (object ["width" "157.5/1125"]))

(define landscape-zero-size
  (object ["height" 50]
          ["width" 50]))

(define normal-ipad-button-size
  (object ["width" "1.1/16"]))

(define first-row-style
  (hash
   "firstRowStyle"
   (object ["size" (object ["height" (json-number "55")])])))

(define first-row-style-landscape
  (hash
   "firstRowStyle"
   (object ["size" (object ["height" (json-number "70")])])))

(define phone-badge-center
  (object ["y" (json-number "0.20000000000000001")]))

(define ipad-top-center
  (object ["y" (json-number "0.29999999999999999")]))

(define ipad-bottom-center
  (object ["y" (json-number "0.65000000000000002")]))

(define left-system-offset
  (object ["x" (json-number "0.25")]
          ["y" (json-number "0.59999999999999998")]))

(define right-system-offset
  (object ["x" (json-number "0.75")]
          ["y" (json-number "0.59999999999999998")]))

(define candidate-insets
  (object ["bottom" 0]
          ["left" 200]
          ["right" 200]
          ["top" 0]))

(define (send-keys-action value)
  (object ["sendKeys" value]))

(define (plain-text-style dark?
                          #:font-size font-size
                          #:text [text #f]
                          #:normal-color [normal-color #f]
                          #:highlight-color [highlight-color #f]
                          #:center [center #f]
                          #:font-weight [font-weight #f])
  (append
   (list (cons "buttonStyleType" "text"))
   (if center (list (cons "center" center)) '())
   (list (cons "fontSize" font-size))
   (if font-weight (list (cons "fontWeight" font-weight)) '())
   (list (cons "highlightColor" (or highlight-color (theme-primary dark?)))
         (cons "normalColor" (or normal-color (theme-primary dark?))))
   (if text (list (cons "text" text)) '())))

(define (hint-foreground-style dark? text #:font-size [font-size 26])
  (object ["buttonStyleType" "text"]
          ["fontSize" font-size]
          ["normalColor" (theme-primary dark?)]
          ["text" text]))

(define (phone-shared-style-entries dark?)
  (hash
   "divisionButtonForegroundStyle"
   (plain-text-style dark? #:font-size 22.5 #:text "÷")
   "phoneAlphabeticForegroundStyle"
   (plain-text-style dark? #:font-size 22.5 #:text "")
   "phoneNumberForegroundStyle"
   (plain-text-style dark? #:font-size 20 #:text "")
   "phoneSwipeHintForegroundStyle"
   (hint-foreground-style dark? "")
   "phoneSystemForegroundStyle"
   (plain-text-style dark? #:font-size 16 #:text "")
   "phoneTopBadgeForegroundStyle"
   (plain-text-style dark?
                     #:font-size 11
                     #:text ""
                     #:center phone-badge-center
                     #:normal-color (theme-secondary dark?)
                     #:highlight-color (theme-secondary dark?))))

(define (cell name)
  (object ["Cell" name]))

(define (row-layout names #:style [style #f])
  (object
   ["HStack"
    (append
     (if style (list (cons "style" style)) '())
     (list (cons "subviews"
                 (list->vector
                  (for/list ([name (in-list names)])
                    (cell name))))))]))

(define phone-portrait-layout
  (list->vector
   (list
    (row-layout '("oneButton" "twoButton" "threeButton" "fourButton" "fiveButton"
                  "sixButton" "sevenButton" "eightButton" "nineButton" "zeroButton"))
    (row-layout '("qButton" "wButton" "eButton" "rButton" "tButton"
                  "yButton" "uButton" "iButton" "oButton" "pButton"))
    (row-layout '("aButton" "sButton" "dButton" "fButton" "gButton"
                  "hButton" "jButton" "kButton" "lButton" "semicolonButton"))
    (row-layout '("zButton" "xButton" "cButton" "vButton" "bButton"
                  "nButton" "mButton" "commaButton" "periodButton" "forwardSlashButton"))
    (row-layout '("numericButton" "shiftButton" "apostropheButton"
                  "spaceButton" "backspaceButton" "enterButton")))))

(define phone-landscape-layout
  (list->vector
   (list
    (row-layout '("qButton" "wButton" "eButton" "rButton" "tButton"
                  "sevenButton" "eightButton" "nineButton" "hyphenButton"
                  "yButton" "uButton" "iButton" "oButton" "pButton"))
    (row-layout '("aButton" "sButton" "dButton" "fButton" "gButton"
                  "fourButton" "fiveButton" "sixButton" "plusButton"
                  "hButton" "jButton" "kButton" "lButton" "semicolonButton"))
    (row-layout '("zButton" "xButton" "cButton" "vButton" "bButton"
                  "oneButton" "twoButton" "threeButton" "asteriskButton"
                  "nButton" "mButton" "commaButton" "periodButton" "forwardSlashButton"))
    (row-layout '("numericButton" "shiftButton" "apostropheButton" "spaceButton"
                  "equalButton" "zeroButton" "divisionButton" "spaceButton"
                  "backspaceButton" "enterButton")))))

(define ipad-layout
  (list->vector
   (list
    (row-layout '("graveButton" "oneButton" "twoButton" "threeButton" "fourButton"
                  "fiveButton" "sixButton" "sevenButton" "eightButton" "nineButton"
                  "zeroButton" "hyphenButton" "equalButton" "backspaceButton")
                #:style "firstRowStyle")
    (row-layout '("tabButton" "qButton" "wButton" "eButton" "rButton"
                  "tButton" "yButton" "uButton" "iButton" "oButton"
                  "pButton" "leftChineseBracketButton" "rightChineseBracketButton"
                  "ideographicCommaButton"))
    (row-layout '("asciiModeButton" "aButton" "sButton" "dButton" "fButton"
                  "gButton" "hButton" "jButton" "kButton" "lButton"
                  "chineseSemicolonButton" "leftSingleQuoteButton" "enterButton"))
    (row-layout '("leftshiftButton" "zButton" "xButton" "cButton" "vButton"
                  "bButton" "nButton" "mButton" "chineseCommaButton"
                  "chinesePeriodButton" "forwardSlashButton" "rightshiftButton"))
    (row-layout '("otherKeyboardButton" "numericButton" "spaceButton"
                  "numericButton" "dismissButton")))))

(define portrait-phone-key-specs
  (list
   (phone-key-spec "oneButton" (char-action "1") "1" (char-action "!") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "twoButton" (char-action "2") "2" (char-action "@") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "threeButton" (char-action "3") "3" (char-action "#") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "fourButton" (char-action "4") "4" (char-action "$") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "fiveButton" (char-action "5") "5" (char-action "%") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "sixButton" (char-action "6") "6" (char-action "^") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "sevenButton" (char-action "7") "7" (char-action "&") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "eightButton" (char-action "8") "8" (char-action "*") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "nineButton" (char-action "9") "9" (char-action "(") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "zeroButton" (char-action "0") "0" (char-action ")") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "qButton" (char-action "q") "Q" (char-action "`") #f #t "Q" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "wButton" (char-action "w") "W" (char-action "~") #f #t "W" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "eButton" (char-action "e") "E" (char-action "+") #f #t "E" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "rButton" (char-action "r") "R" (char-action "-") #f #t "R" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "tButton" (char-action "t") "T" (char-action "=") #f #t "T" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "yButton" (char-action "y") "Y" (char-action "_") #f #t "Y" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "uButton" (char-action "u") "U" (char-action "{") #f #t "U" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "iButton" (char-action "i") "I" (char-action "}") #f #t "I" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "oButton" (char-action "o") "O" (char-action "[") #f #t "O" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "pButton" (char-action "p") "P" (char-action "]") #f #t "P" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "aButton" (char-action "a") "A" (char-action "\"") #f #t "A" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "sButton" (char-action "s") "S" (char-action "|") #f #t "S" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "dButton" (char-action "d") "D" (char-action "×") #f #t "D" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "fButton" (char-action "f") "F" (char-action "÷") #f #t "F" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "gButton" (char-action "g") "G" (char-action "↓") #f #t "G" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "hButton" (char-action "h") "H" (char-action "↑") #f #t "H" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "jButton" (char-action "j") "J" (char-action "←") #f #t "J" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "kButton" (char-action "k") "K" (char-action "→") #f #t "K" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "lButton" (char-action "l") "L" (send-keys-action "Control+l") #f #f "L" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "semicolonButton" (char-action ";") ";" (char-action ":") #f #t #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "zButton" (char-action "z") "Z" (shortcut-action "#重输") #f #f "Z" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "xButton" (char-action "x") "X" (shortcut-action "#cut") #f #f "X" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "cButton" (char-action "c") "C" (shortcut-action "#copy") #f #f "C" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "vButton" (char-action "v") "V" (shortcut-action "#paste") #f #f "V" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "bButton" (char-action "b") "B" (keyboard-type-action "symbolic") #f #f "B" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "nButton" (char-action "n") "N" (shortcut-action "#RimeSwitcher") #f #f "N" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "mButton" (char-action "m") "M" "dismissKeyboard" #f #f "M" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "commaButton" (char-action ",") "," (char-action "<") "nextKeyboard" #f #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "periodButton" (char-action ".") "." (char-action ">") (shortcut-action "#方案切换") #f #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "forwardSlashButton" (char-action "/") "/" (char-action "?") (shortcut-action "#简繁切换") #t #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "apostropheButton" (char-action "'") "'" (char-action "\"") #f #t #f portrait-apostrophe-width "phoneAlphabeticForegroundStyle")))

(define landscape-phone-key-specs
  (list
   (phone-key-spec "qButton" (char-action "q") "Q" (char-action "`") #f #t "Q" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "wButton" (char-action "w") "W" (char-action "~") #f #t "W" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "eButton" (char-action "e") "E" (char-action "+") #f #t "E" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "rButton" (char-action "r") "R" (char-action "-") #f #t "R" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "tButton" (char-action "t") "T" (char-action "=") #f #t "T" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "sevenButton" (char-action "7") "7" (char-action "&") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "eightButton" (char-action "8") "8" (char-action "*") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "nineButton" (char-action "9") "9" (char-action "(") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "hyphenButton" (char-action "-") "-" (char-action "——") #f #f #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "yButton" (char-action "y") "Y" (char-action "_") #f #t "Y" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "uButton" (char-action "u") "U" (char-action "{") #f #t "U" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "iButton" (char-action "i") "I" (char-action "}") #f #t "I" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "oButton" (char-action "o") "O" (char-action "[") #f #t "O" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "pButton" (char-action "p") "P" (char-action "]") #f #t "P" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "aButton" (char-action "a") "A" (char-action "\"") #f #t "A" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "sButton" (char-action "s") "S" (char-action "|") #f #t "S" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "dButton" (char-action "d") "D" (char-action "×") #f #t "D" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "fButton" (char-action "f") "F" (char-action "÷") #f #t "F" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "gButton" (char-action "g") "G" (char-action "↓") #f #t "G" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "fourButton" (char-action "4") "4" (char-action "$") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "fiveButton" (char-action "5") "5" (char-action "%") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "sixButton" (char-action "6") "6" (char-action "^") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "plusButton" (char-action "+") "+" (char-action "=") #f #f #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "hButton" (char-action "h") "H" (char-action "↑") #f #t "H" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "jButton" (char-action "j") "J" (char-action "←") #f #t "J" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "kButton" (char-action "k") "K" (char-action "→") #f #t "K" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "lButton" (char-action "l") "L" (send-keys-action "Control+l") #f #f "L" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "semicolonButton" (char-action ";") ";" (char-action ":") #f #t #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "zButton" (char-action "z") "Z" (shortcut-action "#重输") #f #f "Z" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "xButton" (char-action "x") "X" (shortcut-action "#cut") #f #f "X" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "cButton" (char-action "c") "C" (shortcut-action "#copy") #f #f "C" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "vButton" (char-action "v") "V" (shortcut-action "#paste") #f #f "V" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "bButton" (char-action "b") "B" (keyboard-type-action "symbolic") #f #f "B" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "oneButton" (char-action "1") "1" (char-action "!") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "twoButton" (char-action "2") "2" (char-action "@") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "threeButton" (char-action "3") "3" (char-action "#") #f #t #f #f "phoneNumberForegroundStyle")
   (phone-key-spec "asteriskButton" (char-action "*") "*" #f #f #f #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "nButton" (char-action "n") "N" (shortcut-action "#RimeSwitcher") #f #f "N" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "mButton" (char-action "m") "M" "dismissKeyboard" #f #f "M" #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "commaButton" (char-action ",") "," (char-action "<") "nextKeyboard" #f #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "periodButton" (char-action ".") "." (char-action ">") (shortcut-action "#方案切换") #f #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "forwardSlashButton" (char-action "/") "/" (char-action "?") (shortcut-action "#简繁切换") #t #f #f "phoneAlphabeticForegroundStyle")
   (phone-key-spec "apostropheButton" (char-action "'") "'" (char-action "\"") #f #t #f landscape-small-width "phoneAlphabeticForegroundStyle")
   (phone-key-spec "equalButton" (char-action "=") "=" (char-action "+") #f #f #f landscape-small-width "phoneAlphabeticForegroundStyle")
   (phone-key-spec "zeroButton" (char-action "0") "0" (char-action ")") #f #f #f landscape-zero-size "phoneNumberForegroundStyle")
   (phone-key-spec "divisionButton" (char-action "÷") "÷" #f #f #f #f landscape-small-width "divisionButtonForegroundStyle")))

(define soft46-ipad-letter-specs
  (list
   (list "qButton" "q" (char-action "`"))
   (list "wButton" "w" (char-action "~"))
   (list "eButton" "e" (char-action "+"))
   (list "rButton" "r" (char-action "-"))
   (list "tButton" "t" (char-action "="))
   (list "yButton" "y" (char-action "_"))
   (list "uButton" "u" (char-action "{"))
   (list "iButton" "i" (char-action "}"))
   (list "oButton" "o" (char-action "["))
   (list "pButton" "p" (char-action "]"))
   (list "aButton" "a" (char-action "\""))
   (list "sButton" "s" (char-action "|"))
   (list "dButton" "d" (char-action "×"))
   (list "fButton" "f" (char-action "÷"))
   (list "gButton" "g" (char-action "↓"))
   (list "hButton" "h" (char-action "↑"))
   (list "jButton" "j" (char-action "←"))
   (list "kButton" "k" (char-action "→"))
   (list "lButton" "l" (send-keys-action "Control+l"))
   (list "zButton" "z" (shortcut-action "#重输"))
   (list "xButton" "x" (shortcut-action "#cut"))
   (list "cButton" "c" (shortcut-action "#copy"))
   (list "vButton" "v" (shortcut-action "#paste"))
   (list "bButton" "b" (keyboard-type-action "symbolic"))
   (list "nButton" "n" (shortcut-action "#RimeSwitcher"))
   (list "mButton" "m" "dismissKeyboard")))

(define soft46-ipad-dual-specs
  (list
   (list "graveButton" "`" char-action "~" char-action 26)
   (list "oneButton" "1" char-action "!" char-action 20)
   (list "twoButton" "2" char-action "@" char-action 20)
   (list "threeButton" "3" char-action "#" char-action 20)
   (list "fourButton" "4" char-action "$" char-action 20)
   (list "fiveButton" "5" char-action "%" char-action 20)
   (list "sixButton" "6" char-action "^" char-action 20)
   (list "sevenButton" "7" char-action "&" char-action 20)
   (list "eightButton" "8" char-action "*" char-action 20)
   (list "nineButton" "9" char-action "(" char-action 20)
   (list "zeroButton" "0" char-action ")" char-action 20)
   (list "hyphenButton" "-" char-action "——" char-action 26)
   (list "equalButton" "=" char-action "+" char-action 26)
   (list "leftChineseBracketButton" "【" symbol-action "「" symbol-action 26)
   (list "rightChineseBracketButton" "】" symbol-action "」" symbol-action 26)
   (list "ideographicCommaButton" "、" symbol-action "|" symbol-action 26)
   (list "chineseSemicolonButton" "；" symbol-action "：" symbol-action 26)
   (list "leftSingleQuoteButton" "’" symbol-action "”" symbol-action 26)
   (list "chineseCommaButton" "，" symbol-action "《" symbol-action 26)
   (list "chinesePeriodButton" "。" symbol-action "》" symbol-action 26)
   (list "forwardSlashButton" "/" char-action "?" char-action 26)))

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

(define (phone-key-entry dark? spec)
  (define name (phone-key-spec-name spec))
  (define hint-style-name (string-append name "HintStyle"))
  (define hint-foreground-name (string-append name "HintForegroundStyle"))
  (define foreground-style
    (if (phone-key-spec-badge? spec)
        (array (phone-key-spec-primary-style spec) "phoneTopBadgeForegroundStyle")
        (array (phone-key-spec-primary-style spec))))
  (hash
   name
   (append
    (list (cons "action" (phone-key-spec-action spec))
          (cons "backgroundStyle" "alphabeticButtonBackgroundStyle")
          (cons "foregroundStyle" foreground-style)
          (cons "hintStyle" hint-style-name))
    (if (phone-key-spec-size spec)
        (list (cons "size" (phone-key-spec-size spec)))
        '())
    (if (phone-key-spec-swipe-up spec)
        (list (cons "swipeUpAction" (phone-key-spec-swipe-up spec)))
        '())
    (if (phone-key-spec-swipe-down spec)
        (list (cons "swipeDownAction" (phone-key-spec-swipe-down spec)))
        '())
    (if (phone-key-spec-uppercase-text spec)
        (list (cons "uppercasedStateAction"
                    (char-action (phone-key-spec-uppercase-text spec)))
              (cons "uppercasedStateForegroundStyle"
                    (phone-key-spec-primary-style spec)))
        '()))
   hint-foreground-name
   (hint-foreground-style dark? (phone-key-spec-hint-text spec))
   hint-style-name
   (append
    (list (cons "backgroundStyle" "alphabeticHintBackgroundStyle")
          (cons "foregroundStyle" hint-foreground-name)
          (cons "size" hint-size))
    (if (phone-key-spec-swipe-up spec)
        (list (cons "swipeUpForegroundStyle" "phoneSwipeHintForegroundStyle"))
        '())
    (if (phone-key-spec-swipe-down spec)
        (list (cons "swipeDownForegroundStyle" "phoneSwipeHintForegroundStyle"))
        '()))))

(define (phone-simple-system-entry name action size foreground-style
                                   #:background [background "systemButtonBackgroundStyle"]
                                   #:swipe-up [swipe-up #f]
                                   #:swipe-down [swipe-down #f]
                                   #:repeat-action [repeat-action #f]
                                   #:notification [notification #f]
                                   #:caps-locked-style [caps-locked-style #f]
                                   #:uppercased-style [uppercased-style #f]
                                   #:badge? [badge? #f])
  (hash
   name
   (append
    (list (cons "action" action)
          (cons "backgroundStyle" background)
          (cons "foregroundStyle"
                (if badge?
                    (array foreground-style "phoneTopBadgeForegroundStyle")
                    foreground-style)))
    (if caps-locked-style
        (list (cons "capsLockedStateForegroundStyle" caps-locked-style))
        '())
    (if size
        (list (cons "size" size))
        '())
    (if swipe-up
        (list (cons "swipeUpAction" swipe-up))
        '())
    (if swipe-down
        (list (cons "swipeDownAction" swipe-down))
        '())
    (if repeat-action
        (list (cons "repeatAction" repeat-action))
        '())
    (if notification
        (list (cons "notification" notification))
        '())
    (if uppercased-style
        (list (cons "uppercasedStateForegroundStyle" uppercased-style))
        '()))))

(define (phone-space-entry)
  (phone-simple-system-entry
   "spaceButton"
   "space"
   #f
   "phoneAlphabeticForegroundStyle"
   #:background "alphabeticButtonBackgroundStyle"
   #:swipe-up (shortcut-action "#中英切换")
   #:notification (array "preeditChangedForSpaceButtonNotification")))

(define (phone-shift-entry size)
  (phone-simple-system-entry
   "shiftButton"
   "shift"
   size
   "phoneSystemForegroundStyle"
   #:swipe-up (send-keys-action "Tab")
   #:caps-locked-style "phoneSystemForegroundStyle"
   #:uppercased-style "phoneSystemForegroundStyle"
   #:badge? #t))

(define (phone-system-entries portrait?)
  (bundle
   (phone-simple-system-entry
    "numericButton"
    (shortcut-action "#中英切换")
    (if portrait? portrait-system-width landscape-numeric-width)
    "phoneSystemForegroundStyle")
   (phone-shift-entry (if portrait? portrait-system-width landscape-small-width))
   (phone-space-entry)
   (phone-simple-system-entry
    "backspaceButton"
    "backspace"
    (if portrait? portrait-system-width landscape-backspace-width)
    "phoneSystemForegroundStyle"
    #:swipe-up (send-keys-action "Shift+Return")
    #:repeat-action "backspace")
   (phone-simple-system-entry
    "enterButton"
    "enter"
    portrait-system-width
    "phoneSystemForegroundStyle"
    #:swipe-up (send-keys-action "Control+Return")
    #:notification (array "returnKeyTypeChangedNotification"
                          "preeditChangedForEnterButtonNotification"))))

(define (phone-page dark? portrait? specs layout)
  (define combined
    (hash-union
     (make-phone-base-page dark? portrait?
                           #:keyboard-height (if portrait? "250" "160"))
     (phone-shared-style-entries dark?)
     (hash "keyboardLayout" layout)
     (apply bundle
            (append
             (for/list ([spec (in-list specs)])
               (phone-key-entry dark? spec))
             (list (phone-system-entries portrait?))))
     #:combine/key (lambda (_ _left right) right)))
  (auto-ordered-page combined))

(define (ipad-hint-style foreground-style)
  (object ["backgroundStyle" "alphabeticHintBackgroundStyle"]
          ["foregroundStyle" foreground-style]))

(define (ipad-letter-entry dark? spec)
  (define name (list-ref spec 0))
  (define text (list-ref spec 1))
  (define swipe-up (list-ref spec 2))
  (define uppercase (string-upcase text))
  (hash
   name
   (object ["action" (char-action text)]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" (string-append name "ForegroundStyle")]
           ["hintStyle" (string-append name "HintStyle")]
           ["size" normal-ipad-button-size]
           ["swipeUpAction" swipe-up]
           ["uppercasedStateAction" (char-action uppercase)]
           ["uppercasedStateForegroundStyle" (string-append name "UppercaseForegroundStyle")])
   (string-append name "ForegroundStyle")
   (plain-text-style dark? #:font-size 22.5 #:text text)
   (string-append name "HintForegroundStyle")
   (hint-foreground-style dark? uppercase)
   (string-append name "HintStyle")
   (ipad-hint-style (string-append name "HintForegroundStyle"))
   (string-append name "UppercaseForegroundStyle")
   (plain-text-style dark? #:font-size 22.5 #:text uppercase)))

(define (ipad-dual-entry dark? spec)
  (define name (list-ref spec 0))
  (define base-text (list-ref spec 1))
  (define base-action (list-ref spec 2))
  (define top-text (list-ref spec 3))
  (define top-action (list-ref spec 4))
  (define hint-font-size (list-ref spec 5))
  (define foreground-style
    (if (string=? name "graveButton")
        (array (string-append name "ForegroundStyle")
               (string-append name "TopForegroundStyle"))
        (array (string-append name "TopForegroundStyle")
               (string-append name "ForegroundStyle"))))
  (hash
   name
   (object ["action" (base-action base-text)]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" foreground-style]
           ["hintStyle" (string-append name "HintStyle")]
           ["size" normal-ipad-button-size]
           ["swipeUpAction" (top-action top-text)])
   (string-append name "ForegroundStyle")
   (plain-text-style dark?
                     #:font-size 14
                     #:text base-text
                     #:center ipad-bottom-center)
   (string-append name "TopForegroundStyle")
   (plain-text-style dark?
                     #:font-size 14
                     #:text top-text
                     #:center ipad-top-center)
   (string-append name "HintForegroundStyle")
   (hint-foreground-style dark? base-text #:font-size hint-font-size)
   (string-append name "HintStyle")
   (ipad-hint-style (string-append name "HintForegroundStyle"))))

(define (centered-system-image-style dark? image-name center
                                     #:highlight-image [highlight-image #f])
  (append
   (system-image-style dark? image-name #:highlight-image highlight-image)
   (list (cons "center" center))))

(define (ipad-blank-system-style dark?)
  (plain-text-style dark? #:font-size 16 #:text ""))

(define (ipad-text-system-entry dark? name action width text)
  (hash
   name
   (object ["action" action]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" (string-append name "ForegroundStyle")]
           ["size" (object ["width" width])])
   (string-append name "ForegroundStyle")
   (plain-text-style dark? #:font-size 16 #:text text)))

(define (ipad-image-system-entry dark? name action width image-name
                                 #:center [center #f]
                                 #:highlight-image [highlight-image #f]
                                 #:swipe-up [swipe-up #f]
                                 #:swipe-down [swipe-down #f]
                                 #:repeat-action [repeat-action #f])
  (hash
   name
   (append
    (list (cons "action" action)
          (cons "backgroundStyle" "systemButtonBackgroundStyle")
          (cons "foregroundStyle" (string-append name "ForegroundStyle"))
          (cons "size" (object ["width" width])))
    (if swipe-up (list (cons "swipeUpAction" swipe-up)) '())
    (if swipe-down (list (cons "swipeDownAction" swipe-down)) '())
    (if repeat-action (list (cons "repeatAction" repeat-action)) '()))
   (string-append name "ForegroundStyle")
   (if center
       (centered-system-image-style dark? image-name center #:highlight-image highlight-image)
       (system-image-style dark? image-name #:highlight-image highlight-image))))

(define (ipad-shift-entries dark?)
  (hash
   "leftshiftButton"
   (object ["action" "shift"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["capsLockedStateForegroundStyle" "shiftButtonCapsLockedForegroundStyle"]
           ["foregroundStyle" "leftshiftButtonForegroundStyle"]
           ["size" (object ["width" "2.5/16"])]
           ["swipeUpAction" (send-keys-action "Tab")]
           ["uppercasedStateForegroundStyle" "shiftButtonUppercasedForegroundStyle"])
   "leftshiftButtonForegroundStyle"
   (system-image-style dark? "shift")
   "rightshiftButton"
   (object ["action" "shift"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["capsLockedStateForegroundStyle" "shiftButtonCapsLockedForegroundStyle"]
           ["foregroundStyle" "rightshiftButtonForegroundStyle"]
           ["size" (object ["width" "2.5/16"])]
           ["swipeUpAction" (send-keys-action "Tab")]
           ["uppercasedStateForegroundStyle" "shiftButtonUppercasedForegroundStyle"])
   "rightshiftButtonForegroundStyle"
   (system-image-style dark? "shift")
   "shiftButtonCapsLockedForegroundStyle"
   (system-image-style dark? "capslock.fill")
   "shiftButtonUppercasedForegroundStyle"
   (system-image-style dark? "shift.fill")))

(define (ipad-system-entries dark?)
  (bundle
   (ipad-text-system-entry dark? "asciiModeButton" (shortcut-action "#中英切换") "3.9/32" "中/英")
   (ipad-image-system-entry dark? "tabButton" "tab" "1.7/16" "arrow.right.to.line" #:center left-system-offset)
   (ipad-image-system-entry dark?
                            "backspaceButton"
                            "backspace"
                            "1.7/16"
                            "delete.left"
                            #:center right-system-offset
                            #:highlight-image "delete.left.fill"
                            #:swipe-up (send-keys-action "Shift+Return")
                            #:repeat-action "backspace")
   (hash
    "numericButton"
    (object ["action" (shortcut-action "#中英切换")]
            ["backgroundStyle" "systemButtonBackgroundStyle"]
            ["foregroundStyle" "numericButtonForegroundStyle"]
            ["size" (object ["width" "1.65/16"])])
    "numericButtonForegroundStyle"
    (ipad-blank-system-style dark?))
   (ipad-image-system-entry dark? "otherKeyboardButton" "nextKeyboard" "1.65/16" "globe")
   (ipad-image-system-entry dark? "dismissButton" "dismissKeyboard" "1.65/16" "keyboard.chevron.compact.down")
   (hash
    "spaceButton"
    (object ["action" "space"]
            ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
            ["foregroundStyle" "spaceButtonForegroundStyle"]
            ["notification" (array "preeditChangedForSpaceButtonNotification")]
            ["swipeUpAction" (shortcut-action "#中英切换")])
    "spaceButtonForegroundStyle"
    (system-image-style dark? "space"))
   (hash
    "enterButton"
    (object ["action" "enter"]
            ["backgroundStyle" enter-background-style]
            ["foregroundStyle" enter-foreground-style]
            ["notification" (array "returnKeyTypeChangedNotification"
                                   "preeditChangedForEnterButtonNotification")]
            ["size" (object ["width" "3.9/32"])]
            ["swipeUpAction" (send-keys-action "Control+Return")])
    "enterButtonForegroundStyle"
    (plain-text-style dark? #:font-size 16 #:text "$returnKeyType"))
   (ipad-shift-entries dark?)))

(define (ipad-page dark? portrait?)
  (define combined
    (hash-union
     (make-ipad-base-page
      dark?
      portrait?
      #:keyboard-height (if portrait? "375" "500")
      #:extra
      (hash
       "horizontalCandidatesStyle"
       (object ["backgroundStyle" "keyboardBackgroundStyle"]
               ["insets" candidate-insets])
       "preeditStyle"
       (object ["backgroundStyle" "keyboardBackgroundStyle"]
               ["foregroundStyle" "preeditForegroundStyle"]
               ["insets" candidate-insets])))
     (if portrait? first-row-style first-row-style-landscape)
     (hash "keyboardLayout" ipad-layout)
     (apply bundle
            (append
             (for/list ([spec (in-list soft46-ipad-letter-specs)])
               (ipad-letter-entry dark? spec))
             (for/list ([spec (in-list soft46-ipad-dual-specs)])
               (ipad-dual-entry dark? spec))
             (list (ipad-system-entries dark?))))
     #:combine/key (lambda (_ _left right) right)))
  (auto-ordered-page combined))

(define soft46-pinyin-files
  (bundle
   (json-file (yaml-page "light" "pinyinPortrait")
              (phone-page #f #t portrait-phone-key-specs phone-portrait-layout))
   (json-file (yaml-page "dark" "pinyinPortrait")
              (phone-page #t #t portrait-phone-key-specs phone-portrait-layout))
   (json-file (yaml-page "light" "pinyinLandscape")
              (phone-page #f #f landscape-phone-key-specs phone-landscape-layout))
   (json-file (yaml-page "dark" "pinyinLandscape")
              (phone-page #t #f landscape-phone-key-specs phone-landscape-layout))
   (json-file (yaml-page "light" "iPadPinyinPortrait")
              (ipad-page #f #t))
   (json-file (yaml-page "dark" "iPadPinyinPortrait")
              (ipad-page #t #t))
   (json-file (yaml-page "light" "iPadPinyinLandscape")
              (ipad-page #f #f))
   (json-file (yaml-page "dark" "iPadPinyinLandscape")
              (ipad-page #t #f))))
