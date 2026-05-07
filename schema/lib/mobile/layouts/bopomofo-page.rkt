#lang racket/base

(require racket/hash
         "base-page.rkt"
         "../core/dsl.rkt"
         "../keysets/pinyin-common.rkt")

(provide bopomofo-pinyin-files)

(struct bopomofo-spec (name label code width swipe-up-label swipe-up-code) #:transparent)

(define (spec name label code width #:swipe-up-label [swipe-up-label #f] #:swipe-up-code [swipe-up-code #f])
  (bopomofo-spec name label code width swipe-up-label swipe-up-code))

(define phone-width "112.5/1125")

(define bopomofo-button-center
  (object ["x" (json-number "0.5")]
          ["y" (json-number "0.54000000000000004")]))

(define bopomofo-shared-primary-center
  (object ["x" (json-number "0.30")]
          ["y" (json-number "0.54")]))

(define bopomofo-shared-secondary-center
  (object ["x" (json-number "0.70")]
          ["y" (json-number "0.60")]))

(define row1
  (list
   (spec "boButton" "ㄅ" "1" phone-width)
   (spec "deButton" "ㄉ" "2" phone-width)
   (spec "thirdToneButton" "ˇ" "3" phone-width)
   (spec "fourthToneButton" "ˋ" "4" phone-width)
   (spec "zhiButton" "ㄓ" "5" phone-width)
   (spec "secondToneButton" "ˊ" "6" phone-width)
   (spec "lightToneButton" "˙" "7" phone-width)
   (spec "aButtonZhuyin" "ㄚ" "8" phone-width)
   (spec "aiButton" "ㄞ" "9" phone-width)
   (spec "anButton" "ㄢ" "0" phone-width #:swipe-up-label "ㄦ" #:swipe-up-code "-")))

(define row2
  (list
   (spec "poButton" "ㄆ" "q" phone-width)
   (spec "teButton" "ㄊ" "w" phone-width)
   (spec "geButton" "ㄍ" "e" phone-width)
   (spec "jiButton" "ㄐ" "r" phone-width)
   (spec "chiButton" "ㄔ" "t" phone-width)
   (spec "ziButton" "ㄗ" "y" phone-width)
   (spec "yiButton" "ㄧ" "u" phone-width)
   (spec "oButtonZhuyin" "ㄛ" "i" phone-width)
   (spec "eiButton" "ㄟ" "o" phone-width)
   (spec "enButton" "ㄣ" "p" phone-width)))

(define row3
  (list
   (spec "moButton" "ㄇ" "a" phone-width)
   (spec "neButton" "ㄋ" "s" phone-width)
   (spec "keButton" "ㄎ" "d" phone-width)
   (spec "qiButton" "ㄑ" "f" phone-width)
   (spec "shiButton" "ㄕ" "g" phone-width)
   (spec "ciButton" "ㄘ" "h" phone-width)
   (spec "wuButton" "ㄨ" "j" phone-width)
   (spec "eButtonZhuyin" "ㄜ" "k" phone-width)
   (spec "aoButton" "ㄠ" "l" phone-width)
   (spec "angButton" "ㄤ" ";" phone-width)))

(define row4
  (list
   (spec "foButton" "ㄈ" "z" phone-width)
   (spec "leButton" "ㄌ" "x" phone-width)
   (spec "heButton" "ㄏ" "c" phone-width)
   (spec "xiButton" "ㄒ" "v" phone-width)
   (spec "riButton" "ㄖ" "b" phone-width)
   (spec "siButton" "ㄙ" "n" phone-width)
   (spec "yuButton" "ㄩ" "m" phone-width)
   (spec "ehButton" "ㄝ" "," phone-width)
   (spec "ouButton" "ㄡ" "." phone-width)
   (spec "engButton" "ㄥ" "/" phone-width)))

(define keyboard-layout
  (array
   (object ["HStack"
            (object ["subviews"
                     (list->vector
                      (for/list ([spec (in-list row1)])
                        (object ["Cell" (bopomofo-spec-name spec)])))])])
   (object ["HStack"
            (object ["subviews"
                     (list->vector
                      (for/list ([spec (in-list row2)])
                        (object ["Cell" (bopomofo-spec-name spec)])))])])
   (object ["HStack"
            (object ["subviews"
                     (list->vector
                      (for/list ([spec (in-list row3)])
                        (object ["Cell" (bopomofo-spec-name spec)])))])])
   (object ["HStack"
            (object ["subviews"
                     (list->vector
                      (for/list ([spec (in-list row4)])
                        (object ["Cell" (bopomofo-spec-name spec)])))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "numericButton"])
                            (object ["Cell" "emojiButton"])
                            (object ["Cell" "spaceButton"])
                            (object ["Cell" "backspaceButton"])
                            (object ["Cell" "enterButton"]))])])))

(define (theme-color dark? light dark-value)
  (if dark? dark-value light))

(define (preedit-extra dark?)
  (hash
   "preeditHeight" 36
   "preeditForegroundStyle"
   (object ["buttonStyleType" "text"]
           ["fontSize" 16]
           ["insets" (object ["left" 14] ["right" 14])]
           ["normalColor" (theme-color dark? "#566071" "#E4E9F2")])
   "softPreeditBackgroundStyle"
   (object ["buttonStyleType" "geometry"]
           ["normalColor" (theme-color dark? "#F5F7FA" "#222832")]
           ["normalBorderColor" (theme-color dark? "#D8DDE6" "#39424E")]
           ["borderSize" (json-number "0.5")]
           ["cornerRadius" 14])
   "preeditStyle"
   (object ["insets" (object ["top" 6] ["left" 10] ["right" 10] ["bottom" 2])]
           ["backgroundStyle" "softPreeditBackgroundStyle"]
           ["foregroundStyle" "preeditForegroundStyle"])))

(define (candidate-extra dark?)
  (hash
   "toolbarHeight" 52
   "horizontalCandidateStyle"
   (object ["highlightBackgroundColor" (theme-color dark? "#FFFFFF" "#2C313A")]
           ["preferredBackgroundColor" (theme-color dark? "#FFFFFF" "#2C313A")]
           ["preferredIndexColor" (theme-color dark? "#3F4653" "#EEF2F9")]
           ["preferredTextColor" (theme-color dark? "#2F3541" "#F6F8FB")]
           ["preferredCommentColor" (theme-color dark? "#707786" "#B7BECA")]
           ["indexColor" (theme-color dark? "#6E7482" "#B7BECA")]
           ["textColor" (theme-color dark? "#333947" "#EDF1F7")]
           ["commentColor" (theme-color dark? "#7A8090" "#A9B0BC")]
           ["indexFontSize" 11]
           ["textFontSize" 17]
           ["commentFontSize" 13])
   "horizontalCandidatesStyle"
   (object ["backgroundStyle" "keyboardBackgroundStyle"]
           ["insets" (object ["top" 10] ["left" 10] ["right" 10] ["bottom" 6])])
   "verticalLastRowStyle"
   (object ["size" (object ["height" 42])])
   "commitCandidateForegroundStyle"
   (text-foreground-style dark?
                          "選定"
                          #:normal-color (theme-color dark? "#39404B" "#F4F7FB")
                          #:highlight-color (theme-color dark? "#39404B" "#F4F7FB"))))

(define (background-extra dark? portrait? device)
  (define insets
    (cond
      [(eq? device 'ipad)
       (if portrait?
           (object ["top" 3] ["left" 3] ["bottom" 3] ["right" 3])
           (object ["top" 4] ["left" 6] ["bottom" 4] ["right" 6]))]
      [portrait? (object ["top" 4] ["left" 3] ["bottom" 4] ["right" 3])]
      [else (object ["top" 3] ["left" 3] ["bottom" 3] ["right" 3])]))
  (hash
   "keyboardBackgroundStyle"
   (object ["buttonStyleType" "geometry"]
           ["normalColor" (theme-color dark? "#ffffff03" "#00000003")])
   "alphabeticButtonBackgroundStyle"
   (object ["buttonStyleType" "geometry"]
           ["normalColor" (theme-color dark? "#FFFFFF" "#707070")]
           ["highlightColor" (theme-color dark? "#E6E6E6" "#4C4C4C")]
           ["cornerRadius" 10]
           ["insets" insets])
   "alphabeticHintBackgroundStyle"
   (object ["buttonStyleType" "geometry"]
           ["normalColor" (theme-color dark? "#FFFFFF" "#707070")]
           ["normalBorderColor" (theme-color dark? "#C6C6C8" "#69686A")]
           ["borderSize" (json-number "0.5")]
           ["cornerRadius" 10])
   "systemButtonBackgroundStyle"
   (object ["buttonStyleType" "geometry"]
           ["normalColor" (theme-color dark? "#E6E6E6" "#4C4C4C")]
           ["highlightColor" (theme-color dark? "#FFFFFF" "#707070")]
           ["cornerRadius" 10]
           ["insets" insets])
   "blueButtonBackgroundStyle"
   (object ["buttonStyleType" "geometry"]
           ["normalColor" "#2F80FF"]
           ["highlightColor" "#216FE8"]
           ["cornerRadius" 10]
           ["insets" insets])))

(define (bopomofo-button-entry dark? spec)
  (define name (bopomofo-spec-name spec))
  (define swipe-up-label (bopomofo-spec-swipe-up-label spec))
  (define swipe-up-code (bopomofo-spec-swipe-up-code spec))
  (define primary-center
    (if swipe-up-label bopomofo-shared-primary-center bopomofo-button-center))
  (define foreground-style
    (if swipe-up-label
        (array (string-append name "SwipeUpForegroundStyle")
               (string-append name "ForegroundStyle"))
        (string-append name "ForegroundStyle")))
  (hash-union
   (hash
    name
    (append
     (object ["action" (char-action (bopomofo-spec-code spec))]
             ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
             ["foregroundStyle" foreground-style]
             ["size" (object ["width" (bopomofo-spec-width spec)])])
     (if swipe-up-code
         (object ["swipeUpAction" (char-action swipe-up-code)])
         '()))
    (string-append name "ForegroundStyle")
    (text-foreground-style dark?
                           (bopomofo-spec-label spec)
                           #:font-size 18
                           #:center primary-center
                           #:font-weight "normal"))
   (if swipe-up-label
       (hash
        (string-append name "SwipeUpForegroundStyle")
        (text-foreground-style dark?
                               swipe-up-label
                               #:font-size 11
                               #:center bopomofo-shared-secondary-center
                               #:font-weight "normal"))
       (hash))))

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

(define (system-entries dark?)
  (hash
   "emojiButton"
   (object ["action" (keyboard-type-action "emojis")]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "emojiButtonForegroundStyle"]
           ["size" (object ["width" "150/1125"])])
   "emojiButtonForegroundStyle"
   (system-image-style dark? "face.smiling" #:font-size 22)
   "numericButton"
   (object ["action" (keyboard-type-action "numeric")]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "numericButtonForegroundStyle"]
           ["size" (object ["width" "140/1125"])])
   "numericButtonForegroundStyle"
   (text-foreground-style dark? "123")
   "spaceButton"
   (object ["action" "space"]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" "spaceButtonForegroundStyle"]
           ["swipeUpAction" (shortcut-action "#次选上屏")]
           ["notification" (array "preeditChangedForSpaceButtonNotification")])
   "spaceButtonForegroundStyle"
   (system-image-style dark? "space")
   "backspaceButton"
   (object ["action" "backspace"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "backspaceButtonForegroundStyle"]
           ["repeatAction" "backspace"]
           ["size" (object ["width" "300/1125"])])
   "backspaceButtonForegroundStyle"
   (system-image-style dark? "delete.left" #:highlight-image "delete.left.fill")
   "enterButton"
   (object ["action" "enter"]
           ["backgroundStyle" enter-background-style]
           ["foregroundStyle" enter-foreground-style]
           ["notification" (array "returnKeyTypeChangedNotification"
                                  "preeditChangedForEnterButtonNotification")]
           ["size" (object ["width" "280/1125"])])
   "enterButtonForegroundStyle"
   (text-foreground-style dark? "$returnKeyType")))

(define (page-hash dark? portrait? device)
  (define keyboard-height
    (case device
      [(ipad) (if portrait? "344" "394")]
      [else (if portrait? "266" "214")]))
  (define base
    (if (eq? device 'ipad)
        (make-ipad-base-page dark? portrait? #:keyboard-height keyboard-height)
        (make-phone-base-page dark? portrait? #:keyboard-height keyboard-height)))
  (define combined
    (hash-union
     base
     (background-extra dark? portrait? device)
     (preedit-extra dark?)
     (candidate-extra dark?)
     (hash "keyboardLayout" keyboard-layout)
     (apply bundle
            (append
             (for/list ([spec (in-list row1)]) (bopomofo-button-entry dark? spec))
             (for/list ([spec (in-list row2)]) (bopomofo-button-entry dark? spec))
             (for/list ([spec (in-list row3)]) (bopomofo-button-entry dark? spec))
             (for/list ([spec (in-list row4)]) (bopomofo-button-entry dark? spec))))
     (system-entries dark?)
     #:combine/key (lambda (_ _left right) right)))
  (auto-ordered-page combined))

(define bopomofo-pinyin-files
  (bundle
   (json-file (yaml-page "light" "pinyinPortrait")
              (page-hash #f #t 'iphone))
   (json-file (yaml-page "dark" "pinyinPortrait")
              (page-hash #t #t 'iphone))
   (json-file (yaml-page "light" "pinyinLandscape")
              (page-hash #f #f 'iphone))
   (json-file (yaml-page "dark" "pinyinLandscape")
              (page-hash #t #f 'iphone))
   (json-file (yaml-page "light" "iPadPinyinPortrait")
              (page-hash #f #t 'ipad))
   (json-file (yaml-page "dark" "iPadPinyinPortrait")
              (page-hash #t #t 'ipad))
   (json-file (yaml-page "light" "iPadPinyinLandscape")
              (page-hash #f #f 'ipad))
   (json-file (yaml-page "dark" "iPadPinyinLandscape")
              (page-hash #t #f 'ipad))))
