#lang racket/base

(require racket/hash
         "../core/dsl.rkt"
         "../core/visual-policy.rkt")

(provide make-phone-base-page
         make-ipad-base-page
         make-secondary-base-page
         system-image-style
         text-foreground-style
         theme-primary
         theme-secondary
         current-primary-light
         current-primary-dark
         current-secondary-light
         current-secondary-dark)

;; Theme color parameters — override with (parameterize ...) to customize
(define current-primary-light   (make-parameter "#000000"))
(define current-primary-dark    (make-parameter "#FFFFFF"))
(define current-secondary-light (make-parameter "#3c3c4399"))
(define current-secondary-dark  (make-parameter "#ebebf599"))

;; Theme color palette
(define (theme-primary dark?)   (if dark? (current-primary-dark)    (current-primary-light)))
(define (theme-secondary dark?) (if dark? (current-secondary-dark)  (current-secondary-light)))
(define (theme-bg-highlight dark?)   (if dark? "#4C4C4C" "#E6E6E6"))
(define (theme-bg-normal dark?)      (if dark? "#707070" "#FFFFFF"))
(define (theme-hint-border dark?)    (if dark? "#69686A" "#C6C6C8"))
(define (theme-blue dark?)           (if dark? "#0A84FF" "#007AFF"))
(define (theme-kb-bg dark?)          (if dark? "#00000003" "#ffffff03"))
(define (theme-separator dark?)      (if dark? "#38383A" "#C6C6C8"))

;; Orientation-dependent insets
(define (phone-button-insets portrait?)
  (let ([tb (if portrait? (json-number "4") (json-number "3"))])
    (object ["bottom" tb] ["left" (json-number "3")] ["right" (json-number "3")] ["top" tb])))

(define (ipad-button-insets portrait?)
  (if portrait?
      (object ["bottom" (json-number "3")]
              ["left" (json-number "3")]
              ["right" (json-number "3")]
              ["top" (json-number "3")])
      (object ["bottom" (json-number "4")]
              ["left" (json-number "6")]
              ["right" (json-number "6")]
              ["top" (json-number "4")])))

;; Geometry background style builder
(define (geometry-style highlight normal insets)
  (object ["buttonStyleType" "geometry"]
          ["cornerRadius" square-key-corner-radius]
          ["highlightColor" highlight]
          ["insets" insets]
          ["normalColor" normal]))

;; System image foreground style
(define (system-image-style dark? image-name
                            #:font-size [font-size (json-number "20")]
                            #:highlight-image [highlight-image #f])
  (append
   (list (cons "buttonStyleType" "systemImage")
         (cons "fontSize" font-size))
   (if highlight-image
       (list (cons "highlightColor" (theme-primary dark?))
             (cons "highlightSystemImageName" highlight-image))
       (list (cons "highlightColor" (theme-primary dark?))))
   (list (cons "normalColor" (theme-primary dark?))
         (cons "systemImageName" image-name))))

;; Text foreground style
(define (text-foreground-style dark? text #:font-size [font-size (json-number "16")]
                               #:normal-color [nc #f]
                               #:highlight-color [hc #f]
                               #:center [center #f]
                               #:font-weight [font-weight #f])
  (append
   (list (cons "buttonStyleType" "text"))
   (if center (list (cons "center" center)) '())
   (list (cons "fontSize" font-size))
   (if font-weight (list (cons "fontWeight" font-weight)) '())
   (list (cons "highlightColor" (or hc (theme-primary dark?)))
         (cons "normalColor" (or nc (theme-primary dark?)))
         (cons "text" text))))

;; Candidate style builder
(define (candidate-style dark? #:insets [insets #f])
  (append
   (list (cons "commentColor" (theme-primary dark?))
         (cons "commentFontSize" (json-number "14"))
         (cons "highlightBackgroundColor" (theme-bg-normal dark?))
         (cons "indexColor" (theme-primary dark?))
         (cons "indexFontSize" (json-number "12")))
   (if insets (list (cons "insets" insets)) '())
   (list (cons "preferredBackgroundColor" (theme-bg-normal dark?))
         (cons "preferredCommentColor" (theme-primary dark?))
         (cons "preferredIndexColor" (theme-primary dark?))
         (cons "preferredTextColor" (theme-primary dark?))
         (cons "textColor" (theme-primary dark?))
         (cons "textFontSize" (json-number "16")))))

;; Conditional background/foreground for enter button
(define return-key-bg-conditions
  (array
   (object ["conditionKey" "$returnKeyType"]
           ["conditionValue" (array (json-number "0") (json-number "2") (json-number "3")
                                    (json-number "5") (json-number "6") (json-number "8")
                                    (json-number "11"))]
           ["styleName" "systemButtonBackgroundStyle"])
   (object ["conditionKey" "$returnKeyType"]
           ["conditionValue" (array (json-number "1") (json-number "4") (json-number "7")
                                    (json-number "9") (json-number "10"))]
           ["styleName" "blueButtonBackgroundStyle"])))

(define return-key-fg-conditions
  (array
   (object ["conditionKey" "$returnKeyType"]
           ["conditionValue" (array (json-number "0") (json-number "2") (json-number "3")
                                    (json-number "5") (json-number "6") (json-number "8")
                                    (json-number "11"))]
           ["styleName" "enterButtonForegroundStyle"])
   (object ["conditionKey" "$returnKeyType"]
           ["conditionValue" (array (json-number "1") (json-number "4") (json-number "7")
                                    (json-number "9") (json-number "10"))]
           ["styleName" "blueButtonForegroundStyle"])))

;; Notification entries shared across pinyin pages
(define preedit-enter-notification
  (object ["backgroundStyle" return-key-bg-conditions]
          ["foregroundStyle" return-key-fg-conditions]
          ["notificationType" "preeditChanged"]))

(define preedit-space-notification
  (object ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
          ["foregroundStyle" "commitCandidateForegroundStyle"]
          ["notificationType" "preeditChanged"]))

(define return-key-type-notification
  (object ["backgroundStyle" "blueButtonBackgroundStyle"]
          ["foregroundStyle" "blueButtonForegroundStyle"]
          ["notificationType" "returnKeyType"]
          ["returnKeyType" (array (json-number "1") (json-number "4") (json-number "7"))]))

;; Core entries shared by ALL phone-sized base pages (pinyin + secondary)
(define (core-base-entries dark? keyboard-height button-insets)
  (hash
   ;; Background styles
   "alphabeticButtonBackgroundStyle"
   (geometry-style (theme-bg-highlight dark?) (theme-bg-normal dark?) button-insets)
   "alphabeticHintBackgroundStyle"
   (object ["borderSize" (json-number "0.5")]
           ["buttonStyleType" "geometry"]
           ["cornerRadius" (json-number "10")]
           ["normalBorderColor" (theme-hint-border dark?)]
           ["normalColor" (theme-bg-normal dark?)])
   "blueButtonBackgroundStyle"
   (geometry-style (theme-bg-normal dark?) (theme-blue dark?) button-insets)
   "keyboardBackgroundStyle"
   (object ["buttonStyleType" "geometry"]
           ["normalColor" (theme-kb-bg dark?)])
   "systemButtonBackgroundStyle"
   (geometry-style (theme-bg-normal dark?) (theme-bg-highlight dark?) button-insets)

   ;; Common values
   "buttonStyleType" "text"
   "fontSize" (json-number "26")
   "normalColor" (theme-primary dark?)
   "keyboardHeight" (json-number keyboard-height)
   "keyboardStyle" (object ["backgroundStyle" "keyboardBackgroundStyle"])

   ;; Candidate area
   "candidateContextMenu" (vector)
   "commitCandidateForegroundStyle"
   (text-foreground-style dark? "选定")
   "horizontalCandidateStyle"
   (candidate-style dark?)
   "horizontalCandidates"
   (object ["candidateStyle" "horizontalCandidateStyle"]
           ["type" "horizontalCandidates"])
   "horizontalCandidatesLayout"
   (array (object ["HStack" (object ["subviews"
                                      (array (object ["Cell" "horizontalCandidates"])
                                             (object ["Cell" "expandButton"]))])]))
   "horizontalCandidatesStyle"
   (object ["backgroundStyle" "keyboardBackgroundStyle"]
           ["insets" (object ["bottom" (json-number "1")]
                             ["left" (json-number "3")]
                             ["top" (json-number "8")])])

   ;; Vertical candidates
   "verticalBackspaceButtonStyle"
   (object ["action" "backspace"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "verticalBackspaceButtonStyleForegroundStyle"])
   "verticalBackspaceButtonStyleForegroundStyle"
   (system-image-style dark? "delete.left")
   "verticalCandidateStyle"
   (candidate-style dark? #:insets (object ["bottom" (json-number "4")]
                                           ["left" (json-number "6")]
                                           ["right" (json-number "6")]
                                           ["top" (json-number "4")]))
   "verticalCandidates"
   (object ["candidateStyle" "verticalCandidateStyle"]
           ["insets" (object ["bottom" (json-number "8")]
                             ["left" (json-number "8")]
                             ["right" (json-number "8")]
                             ["top" (json-number "8")])]
           ["maxColumns" (json-number "6")]
           ["maxRows" (json-number "5")]
           ["separatorColor" (theme-separator dark?)]
           ["type" "verticalCandidates"])
   "verticalCandidatesLayout"
   (array (object ["HStack" (object ["subviews"
                                      (array (object ["Cell" "verticalCandidates"]))])])
          (object ["HStack" (object ["style" "verticalLastRowStyle"]
                                    ["subviews"
                                     (array (object ["Cell" "verticalPageUpButtonStyle"])
                                            (object ["Cell" "verticalPageDownButtonStyle"])
                                            (object ["Cell" "verticalReturnButtonStyle"])
                                            (object ["Cell" "verticalBackspaceButtonStyle"]))])]))
   "verticalCandidatesStyle"
   (object ["backgroundStyle" "keyboardBackgroundStyle"])
   "verticalLastRowStyle"
   (object ["size" (object ["height" (json-number "45")])])
   "verticalPageDownButtonStyle"
   (object ["action" (object ["shortcut" "#verticalCandidatesPageDown"])]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "verticalPageDownButtonStyleForegroundStyle"])
   "verticalPageDownButtonStyleForegroundStyle"
   (system-image-style dark? "chevron.down")
   "verticalPageUpButtonStyle"
   (object ["action" (object ["shortcut" "#verticalCandidatesPageUp"])]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "verticalPageUpButtonStyleForegroundStyle"])
   "verticalPageUpButtonStyleForegroundStyle"
   (system-image-style dark? "chevron.up")
   "verticalReturnButtonStyle"
   (object ["action" (object ["shortcut" "#candidatesBarStateToggle"])]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "verticalReturnButtonStyleForegroundStyle"])
   "verticalReturnButtonStyleForegroundStyle"
   (system-image-style dark? "return")

   ;; Notifications
   "preeditChangedForEnterButtonNotification"
   preedit-enter-notification
   "preeditChangedForSpaceButtonNotification"
   preedit-space-notification
   "returnKeyTypeChangedNotification"
   return-key-type-notification

   ;; Toolbar and preedit
   "toolbarHeight" (json-number "40")
   "toolbarLayout" '()
   "toolbarStyle" (object ["backgroundStyle" "keyboardBackgroundStyle"])
   "preeditForegroundStyle"
   (object ["buttonStyleType" "text"]
           ["fontSize" (json-number "17")]
           ["normalColor" (theme-primary dark?)])
   "preeditHeight" (json-number "25")
   "preeditStyle"
   (object ["backgroundStyle" "keyboardBackgroundStyle"]
           ["foregroundStyle" "preeditForegroundStyle"]
           ["insets" (object ["left" (json-number "4")]
                             ["top" (json-number "2")])])))

;; System button entries for pinyin-type pages (backspace, shift, space, enter, expand, numeric)
(define (pinyin-system-button-entries dark?)
  (hash
   "backspaceButton"
   (object ["action" "backspace"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["bounds" (object ["alignment" "right"] ["width" "151/168.75"])]
           ["foregroundStyle" "backspaceButtonForegroundStyle"]
           ["repeatAction" "backspace"]
           ["size" (object ["width" "168.75/1125"])])
   "backspaceButtonForegroundStyle"
   (system-image-style dark? "delete.left" #:highlight-image "delete.left.fill")
   "blueButtonForegroundStyle"
   (text-foreground-style dark? "$returnKeyType" #:normal-color "#FFFFFF")
   "enterButton"
   (object ["action" "enter"]
           ["backgroundStyle" return-key-bg-conditions]
           ["foregroundStyle" return-key-fg-conditions]
           ["notification" (array "returnKeyTypeChangedNotification"
                                   "preeditChangedForEnterButtonNotification")]
           ["size" (object ["width" "280/1125"])])
   "enterButtonForegroundStyle"
   (text-foreground-style dark? "$returnKeyType")
   "expandButton"
   (object ["action" (object ["shortcut" "#candidatesBarStateToggle"])]
           ["foregroundStyle" "expandButtonForegroundStyle"]
           ["size" (object ["width" (json-number "44")])])
   "expandButtonForegroundStyle"
   (system-image-style dark? "chevron.forward")
   "numericButton"
   (object ["action" (object ["keyboardType" "numeric"])]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "numericButtonForegroundStyle"]
           ["size" (object ["width" "280/1125"])])
   "numericButtonForegroundStyle"
   (text-foreground-style dark? "123")
   "shiftButton"
   (object ["action" "shift"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["bounds" (object ["alignment" "left"] ["width" "151/168.75"])]
           ["capsLockedStateForegroundStyle" "shiftButtonCapsLockedForegroundStyle"]
           ["foregroundStyle" "shiftButtonForegroundStyle"]
           ["size" (object ["width" "168.75/1125"])]
           ["uppercasedStateForegroundStyle" "shiftButtonUppercasedForegroundStyle"])
   "shiftButtonCapsLockedForegroundStyle"
   (system-image-style dark? "capslock.fill")
   "shiftButtonForegroundStyle"
   (system-image-style dark? "shift")
   "shiftButtonUppercasedForegroundStyle"
   (system-image-style dark? "shift.fill")
   "spaceButton"
   (object ["action" "space"]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" "spaceButtonForegroundStyle"]
           ["notification" (array "preeditChangedForSpaceButtonNotification")]
           ["swipeUpAction" (object ["shortcut" "#次选上屏"])])
   "spaceButtonForegroundStyle"
   (system-image-style dark? "space")))

;; Full phone base page for pinyin keyboards (standard, hybrid, flypy18)
(define (make-phone-base-page dark? portrait?
                              #:keyboard-height keyboard-height
                              #:extra [extra (hash)])
  (hash-union (core-base-entries dark? keyboard-height (phone-button-insets portrait?))
              (pinyin-system-button-entries dark?)
              extra
              #:combine/key (lambda (_ _left right) right)))

(define (make-ipad-base-page dark? portrait?
                             #:keyboard-height keyboard-height
                             #:extra [extra (hash)])
  (hash-union (core-base-entries dark? keyboard-height (ipad-button-insets portrait?))
              extra
              #:combine/key (lambda (_ _left right) right)))

;; Base page for secondary keyboards (numeric, symbolic) - no system buttons
(define (make-secondary-base-page dark? portrait?
                                  #:keyboard-height keyboard-height
                                  #:extra [extra (hash)])
  (hash-union (core-base-entries dark? keyboard-height (phone-button-insets portrait?))
              extra
              #:combine/key (lambda (_ _left right) right)))
