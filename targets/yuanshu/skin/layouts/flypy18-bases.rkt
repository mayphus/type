#lang racket/base

(require racket/hash
         racket/list
         "../core/dsl.rkt"
         "base-page.rkt")

(provide flypy18-portrait-light-base
         flypy18-portrait-dark-base
         flypy18-landscape-light-base
         flypy18-landscape-dark-base
         flypy18-alt-portrait-light-base
         flypy18-alt-portrait-dark-base
         flypy18-alt-landscape-light-base
         flypy18-alt-landscape-dark-base)

;; Flypy18 system buttons differ from standard in sizes and no bounds
(define (flypy18-system-overrides dark?)
  (hash
   "backspaceButton"
   (object ["action" "backspace"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "backspaceButtonForegroundStyle"]
           ["repeatAction" "backspace"]
           ["size" (object ["width" "160.7142857143/1125"])])
   "enterButton"
   (object ["action" "enter"]
           ["backgroundStyle"
            (array
             (object ["conditionKey" "$returnKeyType"]
                     ["conditionValue" (array (json-number "0") (json-number "2") (json-number "3")
                                              (json-number "5") (json-number "6") (json-number "8")
                                              (json-number "11"))]
                     ["styleName" "systemButtonBackgroundStyle"])
             (object ["conditionKey" "$returnKeyType"]
                     ["conditionValue" (array (json-number "1") (json-number "4") (json-number "7")
                                              (json-number "9") (json-number "10"))]
                     ["styleName" "blueButtonBackgroundStyle"]))]
           ["foregroundStyle"
            (array
             (object ["conditionKey" "$returnKeyType"]
                     ["conditionValue" (array (json-number "0") (json-number "2") (json-number "3")
                                              (json-number "5") (json-number "6") (json-number "8")
                                              (json-number "11"))]
                     ["styleName" "enterButtonForegroundStyle"])
             (object ["conditionKey" "$returnKeyType"]
                     ["conditionValue" (array (json-number "1") (json-number "4") (json-number "7")
                                              (json-number "9") (json-number "10"))]
                     ["styleName" "blueButtonForegroundStyle"]))]
           ["notification" (array "returnKeyTypeChangedNotification"
                                   "preeditChangedForEnterButtonNotification")]
           ["size" (object ["width" "220/1125"])])
   "numericButton"
   (object ["action" (object ["keyboardType" "numeric"])]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "numericButtonForegroundStyle"]
           ["size" (object ["width" "180/1125"])])
   "spaceButton"
   (object ["action" "space"]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" "spaceButtonForegroundStyle"]
           ["notification" (array "preeditChangedForSpaceButtonNotification")]
           ["size" (object ["width" "475/1125"])]
           ["swipeUpAction" (object ["shortcut" "#次选上屏"])])))

;; Flypy18 (alt layout) has shift+emoji+semicolon in the base
(define (flypy18-base dark? portrait?)
  (make-phone-base-page dark? portrait?
    #:keyboard-height (if portrait? "216" "160")
    #:extra
    (hash-union
     (flypy18-system-overrides dark?)
     (hash
      "shiftButton"
      (object ["action" "shift"]
              ["backgroundStyle" "systemButtonBackgroundStyle"]
              ["capsLockedStateForegroundStyle" "shiftButtonCapsLockedForegroundStyle"]
              ["foregroundStyle" "shiftButtonForegroundStyle"]
              ["size" (object ["width" "160.7142857143/1125"])]
              ["uppercasedStateForegroundStyle" "shiftButtonUppercasedForegroundStyle"])
      "emojiButton"
      (object ["action" (object ["keyboardType" "emojis"])]
              ["backgroundStyle" "systemButtonBackgroundStyle"]
              ["foregroundStyle" "emojiButtonForegroundStyle"]
              ["size" (object ["width" "140/1125"])])
      "emojiButtonForegroundStyle"
      (system-image-style dark? "face.smiling")
      "semicolonButton"
      (object ["action" (object ["character" ";"])]
              ["backgroundStyle" "systemButtonBackgroundStyle"]
              ["foregroundStyle" "semicolonButtonForegroundStyle"]
              ["size" (object ["width" "110/1125"])])
      "semicolonButtonForegroundStyle"
      (text-foreground-style dark? ";")))))

;; Uppercase foreground styles for merged buttons (generated from button names)
(define (uppercase-styles dark? names)
  (for/hash ([name (in-list names)])
    (values (string-append name "ButtonUppercaseForegroundStyle")
            (text-foreground-style dark? (string-upcase (car (regexp-match #rx"^[a-z]+" name)))
                                  #:font-size (json-number "18")))))

(define flypy18-button-names
  '("q18Alt" "we18Alt" "rt18Alt" "y18Alt" "u18Alt" "io18Alt" "p18Alt"
    "a18Alt" "sd18Alt" "fg18Alt" "h18Alt" "jk18Alt" "l18Alt"
    "z18Alt" "xc18Alt" "v18Alt" "bn18Alt" "m18Alt"))

(define (flypy18-full-base dark? portrait?)
  (hash-union (flypy18-base dark? portrait?)
              (uppercase-styles dark? flypy18-button-names)))

(define flypy18-portrait-light-base  (flypy18-full-base #f #t))
(define flypy18-portrait-dark-base   (flypy18-full-base #t #t))
(define flypy18-landscape-light-base (flypy18-full-base #f #f))
(define flypy18-landscape-dark-base  (flypy18-full-base #t #f))

;; Flypy18-alt: uses standard shift, different button widths
(define (flypy18-alt-system-overrides dark?)
  (hash
   "backspaceButton"
   (object ["action" "backspace"]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "backspaceButtonForegroundStyle"]
           ["repeatAction" "backspace"]
           ["size" (object ["width" "140.625/1125"])])
   "enterButton"
   (object ["action" "enter"]
           ["backgroundStyle"
            (array
             (object ["conditionKey" "$returnKeyType"]
                     ["conditionValue" (array (json-number "0") (json-number "2") (json-number "3")
                                              (json-number "5") (json-number "6") (json-number "8")
                                              (json-number "11"))]
                     ["styleName" "systemButtonBackgroundStyle"])
             (object ["conditionKey" "$returnKeyType"]
                     ["conditionValue" (array (json-number "1") (json-number "4") (json-number "7")
                                              (json-number "9") (json-number "10"))]
                     ["styleName" "blueButtonBackgroundStyle"]))]
           ["foregroundStyle"
            (array
             (object ["conditionKey" "$returnKeyType"]
                     ["conditionValue" (array (json-number "0") (json-number "2") (json-number "3")
                                              (json-number "5") (json-number "6") (json-number "8")
                                              (json-number "11"))]
                     ["styleName" "enterButtonForegroundStyle"])
             (object ["conditionKey" "$returnKeyType"]
                     ["conditionValue" (array (json-number "1") (json-number "4") (json-number "7")
                                              (json-number "9") (json-number "10"))]
                     ["styleName" "blueButtonForegroundStyle"]))]
           ["notification" (array "returnKeyTypeChangedNotification"
                                   "preeditChangedForEnterButtonNotification")]
           ["size" (object ["width" "360/1125"])])
   "numericButton"
   (object ["action" (object ["keyboardType" "numeric"])]
           ["backgroundStyle" "systemButtonBackgroundStyle"]
           ["foregroundStyle" "numericButtonForegroundStyle"]
           ["size" (object ["width" "180/1125"])])
   "spaceButton"
   (object ["action" "space"]
           ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
           ["foregroundStyle" "spaceButtonForegroundStyle"]
           ["notification" (array "preeditChangedForSpaceButtonNotification")]
           ["size" (object ["width" "585/1125"])]
           ["swipeUpAction" (object ["shortcut" "#次选上屏"])])))

(define (flypy18-alt-base dark? portrait?)
  (make-phone-base-page dark? portrait?
    #:keyboard-height (if portrait? "216" "160")
    #:extra (flypy18-alt-system-overrides dark?)))

(define flypy18-alt-button-names
  '("q18" "we18" "rt18" "yu18" "io18" "p18"
    "a18" "sd18" "fg18" "hj18" "kl18"
    "z18" "x18" "c18" "v18" "b18" "n18" "m18"))

(define (flypy18-alt-full-base dark? portrait?)
  (hash-union (flypy18-alt-base dark? portrait?)
              (uppercase-styles dark? flypy18-alt-button-names)))

(define flypy18-alt-portrait-light-base  (flypy18-alt-full-base #f #t))
(define flypy18-alt-portrait-dark-base   (flypy18-alt-full-base #t #t))
(define flypy18-alt-landscape-light-base (flypy18-alt-full-base #f #f))
(define flypy18-alt-landscape-dark-base  (flypy18-alt-full-base #t #f))
