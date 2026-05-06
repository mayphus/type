#lang racket/base

(require racket/hash
         "base-page.rkt"
         "../core/dsl.rkt"
         "../keysets/pinyin-common.rkt")

(provide bopomofo-pinyin-files)

(struct bopomofo-spec (name label code width) #:transparent)

(define phone-width "112.5/1125")
(define compact-width "102.27/1125")

(define bopomofo-button-center
  (object ["x" (json-number "0.5")]
          ["y" (json-number "0.54000000000000004")]))

(define row1
  (list
   (bopomofo-spec "boButton" "ㄅ" "1" phone-width)
   (bopomofo-spec "deButton" "ㄉ" "2" phone-width)
   (bopomofo-spec "thirdToneButton" "ˇ" "3" phone-width)
   (bopomofo-spec "fourthToneButton" "ˋ" "4" phone-width)
   (bopomofo-spec "zhiButton" "ㄓ" "5" phone-width)
   (bopomofo-spec "secondToneButton" "ˊ" "6" phone-width)
   (bopomofo-spec "lightToneButton" "˙" "7" phone-width)
   (bopomofo-spec "aButtonZhuyin" "ㄚ" "8" phone-width)
   (bopomofo-spec "aiButton" "ㄞ" "9" phone-width)
   (bopomofo-spec "anButton" "ㄢ" "0" phone-width)))

(define row2
  (list
   (bopomofo-spec "poButton" "ㄆ" "q" phone-width)
   (bopomofo-spec "teButton" "ㄊ" "w" phone-width)
   (bopomofo-spec "geButton" "ㄍ" "e" phone-width)
   (bopomofo-spec "jiButton" "ㄐ" "r" phone-width)
   (bopomofo-spec "chiButton" "ㄔ" "t" phone-width)
   (bopomofo-spec "ziButton" "ㄗ" "y" phone-width)
   (bopomofo-spec "yiButton" "ㄧ" "u" phone-width)
   (bopomofo-spec "oButtonZhuyin" "ㄛ" "i" phone-width)
   (bopomofo-spec "eiButton" "ㄟ" "o" phone-width)
   (bopomofo-spec "enButton" "ㄣ" "p" phone-width)))

(define row3
  (list
   (bopomofo-spec "moButton" "ㄇ" "a" phone-width)
   (bopomofo-spec "neButton" "ㄋ" "s" phone-width)
   (bopomofo-spec "keButton" "ㄎ" "d" phone-width)
   (bopomofo-spec "qiButton" "ㄑ" "f" phone-width)
   (bopomofo-spec "shiButton" "ㄕ" "g" phone-width)
   (bopomofo-spec "ciButton" "ㄘ" "h" phone-width)
   (bopomofo-spec "wuButton" "ㄨ" "j" phone-width)
   (bopomofo-spec "eButtonZhuyin" "ㄜ" "k" phone-width)
   (bopomofo-spec "aoButton" "ㄠ" "l" phone-width)
   (bopomofo-spec "angButton" "ㄤ" ";" phone-width)))

(define row4
  (list
   (bopomofo-spec "foButton" "ㄈ" "z" compact-width)
   (bopomofo-spec "leButton" "ㄌ" "x" compact-width)
   (bopomofo-spec "heButton" "ㄏ" "c" compact-width)
   (bopomofo-spec "xiButton" "ㄒ" "v" compact-width)
   (bopomofo-spec "riButton" "ㄖ" "b" compact-width)
   (bopomofo-spec "siButton" "ㄙ" "n" compact-width)
   (bopomofo-spec "yuButton" "ㄩ" "m" compact-width)
   (bopomofo-spec "ehButton" "ㄝ" "," compact-width)
   (bopomofo-spec "ouButton" "ㄡ" "." compact-width)
   (bopomofo-spec "engButton" "ㄥ" "/" compact-width)
   (bopomofo-spec "erButton" "ㄦ" "-" compact-width)))

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
  (hash
   (bopomofo-spec-name spec)
   (object ["action" (char-action (bopomofo-spec-code spec))]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" (string-append (bopomofo-spec-name spec) "ForegroundStyle")]
           ["size" (object ["width" (bopomofo-spec-width spec)])])
   (string-append (bopomofo-spec-name spec) "ForegroundStyle")
   (text-foreground-style dark?
                          (bopomofo-spec-label spec)
                          #:font-size 25
                          #:center bopomofo-button-center
                          #:font-weight "medium")))

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
           ["size" (object ["width" "118/1125"])])
   "emojiButtonForegroundStyle"
   (system-image-style dark? "face.smiling")
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
           ["size" (object ["width" "118/1125"])])
   "backspaceButtonForegroundStyle"
   (system-image-style dark? "delete.left" #:highlight-image "delete.left.fill")
   "enterButton"
   (object ["action" "enter"]
           ["backgroundStyle" enter-background-style]
           ["foregroundStyle" enter-foreground-style]
           ["notification" (array "returnKeyTypeChangedNotification"
                                  "preeditChangedForEnterButtonNotification")]
           ["size" (object ["width" "178/1125"])])
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
