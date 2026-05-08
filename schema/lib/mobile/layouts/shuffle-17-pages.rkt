#lang racket/base

(require racket/hash
         racket/string
         "base-page.rkt"
         "../core/dsl.rkt"
         "../core/builders.rkt"
         "../core/visual-policy.rkt"
         "../keysets/pinyin-common.rkt"
         "standard-ipad-page.rkt")

(provide shuffle-17-pinyin-files
         shuffle-spec
         phone-page
         numeric-small-size
         short-space-size
         short-enter-size
         stroke-size)

(struct shuffle-spec (name code label finals top-symbol side-left side-right swipe-up swipe-down font-size)
  #:transparent)


(define six-column-size
  (square-key-size "187.5/1125"))

(define numeric-small-size
  (object ["width" "90/1125"]))

(define short-space-size
  (object ["width" "267.5/1125"]))

(define short-enter-size
  (object ["width" "200/1125"]))

(define stroke-size
  (square-key-size "113.5/1125"))

(define legend-main-center
  (key-note-position 'center))

(define legend-top-center
  (key-note-position 'top))

(define legend-left-center
  (key-note-position 'left))

(define legend-right-center
  (key-note-position 'right))

(define legend-final-center
  (key-note-position 'bottom))

(define shuffle17-button-specs
  (list
   (shuffle-spec "hpButton" "a" "H P" "a ia ua" "1" "" "" (char-action "1") #f 18)
   (shuffle-spec "sh17Button" "b" "Sh" "en in" "2" "" "" (char-action "2") #f 18)
   (shuffle-spec "zh17Button" "c" "Zh" "ang iao" "3" "" "" (char-action "3") #f 18)
   (shuffle-spec "b17Button" "d" "B" "ao iong" "@" "" "" (char-action "@") #f 18)
   (shuffle-spec "oxvButton" "e" "X" "uai uan" "*" "o" "v" (char-action "*") (keyboard-type-action "emojis") 19)
   (shuffle-spec "smButton" "f" "M S" "ie uo" "#" "" "" (char-action "#") (shortcut-action "#toggleScriptView") 18)
   (shuffle-spec "l17Button" "g" "L" "ai ue" "4" "" "" (char-action "4") #f 18)
   (shuffle-spec "d17Button" "h" "D" "u" "5" "" "" (char-action "5") #f 18)
   (shuffle-spec "y17Button" "i" "Y" "eng ing" "6" "" "" (char-action "6") #f 18)
   (shuffle-spec "wzButton" "j" "W Z" "e" "0" "" "" (char-action "0") (shortcut-action "#showPasteboardView") 18)
   (shuffle-spec "jkButton" "k" "J K" "i" "%" "" "" (char-action "%") #f 18)
   (shuffle-spec "rnButton" "l" "N R" "an" "&" "" "" (char-action "&") #f 18)
   (shuffle-spec "ch17Button" "m" "Ch" "iang ui" "7" "" "" (char-action "7") #f 18)
   (shuffle-spec "qGuideButton" "n" "Q~" "ian uang" "8" "" "" (char-action "8") #f 18)
   (shuffle-spec "g17Button" "o" "G" "ei un" "9" "" "" (char-action "9") #f 18)
   (shuffle-spec "cfButton" "p" "C F" "iu ou" "!" "" "" (char-action "!") #f 18)
   (shuffle-spec "t17Button" "q" "T" "er ong" "?" "" "" (char-action "?") #f 18)))

(define phone-layout
  (array
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "hpButton"])
                            (object ["Cell" "sh17Button"])
                            (object ["Cell" "zh17Button"])
                            (object ["Cell" "b17Button"])
                            (object ["Cell" "oxvButton"])
                            (object ["Cell" "smButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "l17Button"])
                            (object ["Cell" "d17Button"])
                            (object ["Cell" "y17Button"])
                            (object ["Cell" "wzButton"])
                            (object ["Cell" "jkButton"])
                            (object ["Cell" "rnButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "ch17Button"])
                            (object ["Cell" "qGuideButton"])
                            (object ["Cell" "g17Button"])
                            (object ["Cell" "cfButton"])
                            (object ["Cell" "t17Button"])
                            (object ["Cell" "backspaceButton"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "strokeHButton"])
                            (object ["Cell" "strokeSButton"])
                            (object ["Cell" "strokePButton"])
                            (object ["Cell" "strokeNButton"])
                            (object ["Cell" "strokeZButton"])
                            (object ["Cell" "spaceButton"])
                            (object ["Cell" "numericButton"])
                            (object ["Cell" "enterButton"]))])])))

(define (main-style dark? spec)
  (text-foreground-style dark?
                         (shuffle-spec-label spec)
                         #:font-size (shuffle-spec-font-size spec)
                         #:center legend-main-center
                         #:font-weight "medium"))

(define (secondary-style dark? text center)
  (text-foreground-style dark?
                         text
                         #:font-size 9.5
                         #:center center
                         #:normal-color (theme-secondary dark?)
                         #:highlight-color (theme-secondary dark?)))

(define (shuffle-button-entry dark? spec)
  (define name (shuffle-spec-name spec))
  (list
   (cons name
         (append
          (list (cons "action" (char-action (shuffle-spec-code spec)))
                (cons "backgroundStyle" "alphabeticButtonBackgroundStyle")
                (cons "capsLockedStateForegroundStyle"
                      (array (string-append name "MainUppercaseForegroundStyle")
                             (string-append name "TopSymbolForegroundStyle")
                             (string-append name "SideLeftForegroundStyle")
                             (string-append name "SideRightForegroundStyle")
                             (string-append name "FinalForegroundStyle")))
                (cons "foregroundStyle"
                      (array (string-append name "MainForegroundStyle")
                             (string-append name "TopSymbolForegroundStyle")
                             (string-append name "SideLeftForegroundStyle")
                             (string-append name "SideRightForegroundStyle")
                             (string-append name "FinalForegroundStyle")))
                (cons "hintStyle" (string-append name "HintStyle"))
                (cons "size" six-column-size))
          (if (shuffle-spec-swipe-down spec)
              (list (cons "swipeDownAction" (shuffle-spec-swipe-down spec)))
              '())
          (list (cons "swipeUpAction" (shuffle-spec-swipe-up spec))
                (cons "uppercasedStateAction" (char-action (string-upcase (shuffle-spec-code spec))))
                (cons "uppercasedStateForegroundStyle"
                      (array (string-append name "MainUppercaseForegroundStyle")
                             (string-append name "TopSymbolForegroundStyle")
                             (string-append name "SideLeftForegroundStyle")
                             (string-append name "SideRightForegroundStyle")
                             (string-append name "FinalForegroundStyle"))))))
   (cons (string-append name "MainForegroundStyle")
         (main-style dark? spec))
   (cons (string-append name "MainUppercaseForegroundStyle")
         (main-style dark? spec))
   (cons (string-append name "TopSymbolForegroundStyle")
         (secondary-style dark? (shuffle-spec-top-symbol spec) legend-top-center))
   (cons (string-append name "SideLeftForegroundStyle")
         (secondary-style dark? (shuffle-spec-side-left spec) legend-left-center))
   (cons (string-append name "SideRightForegroundStyle")
         (secondary-style dark? (shuffle-spec-side-right spec) legend-right-center))
   (cons (string-append name "FinalForegroundStyle")
         (secondary-style dark? (shuffle-spec-finals spec) legend-final-center))
   (cons (string-append name "HintForegroundStyle")
         (object ["buttonStyleType" "text"]
                 ["fontSize" (json-number "26")]
                 ["normalColor" (theme-primary dark?)]
                 ["text" (shuffle-spec-label spec)]))
   (cons (string-append name "HintStyle")
         (object ["backgroundStyle" "alphabeticHintBackgroundStyle"]
                 ["foregroundStyle" (string-append name "HintForegroundStyle")]
                 ["size" (object ["width" 50] ["height" 50])]))))

(define (stroke-button dark? name text action preedit-text left right)
  (hash
   name
   (object ["action" action]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" (string-append name "ForegroundStyle")]
           ["preeditStateAction" (object ["text" preedit-text])]
           ["size" stroke-size])
   (string-append name "ForegroundStyle")
   (append
    (text-foreground-style dark? text #:font-size 16)
    (list (cons "insets" (object ["top" 4] ["bottom" 4] ["left" left] ["right" right]))))))

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

(define (shuffle17-phone-extra dark?)
  (bundle
   (stroke-button dark? "strokeHButton" "-" (char-action "-") ";h" 3 0)
   (stroke-button dark? "strokeSButton" ":" (char-action ":") ";s" 0 0)
   (stroke-button dark? "strokePButton" "…" (symbol-action "…") ";p" 0 0)
   (stroke-button dark? "strokeNButton" "。" (symbol-action "。") ";n" 0 0)
   (stroke-button dark? "strokeZButton" "，" (symbol-action "，") ";z" 0 3)
   (hash
    "backspaceButton"
    (object ["action" "backspace"]
            ["backgroundStyle" "systemButtonBackgroundStyle"]
            ["foregroundStyle" "backspaceButtonForegroundStyle"]
            ["repeatAction" "backspace"]
            ["size" six-column-size])
    "backspaceButtonForegroundStyle"
    (system-image-style dark? "delete.left" #:highlight-image "delete.left.fill")
    "numericButton"
    (object ["action" (keyboard-type-action "numeric")]
            ["backgroundStyle" "systemButtonBackgroundStyle"]
            ["foregroundStyle" "numericButtonForegroundStyle"]
            ["size" numeric-small-size])
    "numericButtonForegroundStyle"
    (text-foreground-style dark? "123")
    "spaceButton"
    (object ["action" "space"]
            ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
            ["foregroundStyle" "spaceButtonForegroundStyle"]
            ["notification" (array "preeditChangedForSpaceButtonNotification")]
            ["size" short-space-size]
            ["swipeUpAction" (shortcut-action "#次选上屏")])
    "spaceButtonForegroundStyle"
    (system-image-style dark? "space")
    "enterButton"
    (object ["action" "enter"]
            ["backgroundStyle" enter-background-style]
            ["foregroundStyle" enter-foreground-style]
            ["notification" (array "returnKeyTypeChangedNotification"
                                   "preeditChangedForEnterButtonNotification")]
            ["size" short-enter-size])
    "enterButtonForegroundStyle"
    (text-foreground-style dark? "$returnKeyType"))))

(define (phone-page dark? portrait?)
  (make-grid-page dark? portrait?
                  #:base-page-builder (lambda (d p)
                                        (make-phone-base-page d p
                                                              #:keyboard-height (if p "216" "160")
                                                              #:extra (shuffle17-phone-extra d)))
                  #:keyboard-layout phone-layout
                  #:button-specs shuffle17-button-specs
                  #:button-renderer shuffle-button-entry))

(define normal-button-size
  (object ["width" "1.1/16"]))

(define shuffle17-ipad-letter-config
  (hash
   'size-for (lambda (_spec) (values normal-button-size #f '()))
   'centers (hash-set default-legend-centers
                      'symbol (object ["x" (json-number "0.72999999999999998")]
                                      ["y" (json-number "0.20000000000000001")]))
   'abc-font-size 12
   'cangjie-font-size 18
   'symbol-font-size 9
   'flypy-single-font-size (json-number "16.5")
   'flypy-double-font-size (json-number "11.5")
   'hint-style-extra '()))

(define shuffle17-ipad-files
  (make-standard-ipad-pinyin-files
   #:letter-config shuffle17-ipad-letter-config))

(define shuffle-17-pinyin-files
  (bundle (make-pinyin-bundle "pinyinPortrait" "pinyinLandscape" phone-page)
          shuffle17-ipad-files))
