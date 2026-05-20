#lang racket/base

(require racket/hash
         racket/list
         "base-page.rkt"
         "../core/dsl.rkt"
         "../keysets/pinyin-common.rkt")

(provide button-spec
         system-button-spec
         alphabetic-width
         system-width
         large-system-width
         left-system-bounds
         right-system-bounds
         hint-size
         make-phone-secondary-files)

(struct button-spec (name text action-proc swipe-up swipe-up-proc center) #:transparent)
(struct system-button-spec (name text action size bounds) #:transparent)

(define alphabetic-width
  (object ["width" "112.5/1125"]))

(define system-width
  (object ["width" "168.75/1125"]))

(define large-system-width
  (object ["width" "280/1125"]))

(define left-system-bounds
  (object ["alignment" "left"]
          ["width" "151/168.75"]))

(define right-system-bounds
  (object ["alignment" "right"]
          ["width" "151/168.75"]))

(define hint-size
  (object ["height" 50]
          ["width" 50]))

(define (text-style dark? text [center #f] [font-size 22.5])
  (append
   (list (cons "buttonStyleType" "text"))
   (if center (list (cons "center" center)) '())
   (list (cons "fontSize" font-size)
         (cons "highlightColor" (theme-primary dark?))
         (cons "normalColor" (theme-primary dark?))
         (cons "text" text))))

(define (hint-foreground text dark? center)
  (append
   (list (cons "buttonStyleType" "text"))
   (if center (list (cons "center" center)) '())
   (list (cons "fontSize" 26)
         (cons "normalColor" (theme-primary dark?))
         (cons "text" text))))

(define (secondary-button spec dark?)
  (define name (button-spec-name spec))
  (define text (button-spec-text spec))
  (define action-proc (button-spec-action-proc spec))
  (define swipe-up (button-spec-swipe-up spec))
  (define swipe-up-proc (button-spec-swipe-up-proc spec))
  (define center (button-spec-center spec))
  (append
   (list
    (cons name
          (append
           (list (cons "action" (action-proc text))
                 (cons "backgroundStyle" "alphabeticButtonBackgroundStyle")
                 (cons "foregroundStyle" (string-append name "ForegroundStyle"))
                 (cons "hintStyle" (string-append name "HintStyle"))
                 (cons "size" alphabetic-width))
           (if swipe-up
               (list (cons "swipeUpAction" (swipe-up-proc swipe-up)))
               '()))))
   (list
    (cons (string-append name "ForegroundStyle") (text-style dark? text center))
    (cons (string-append name "HintForegroundStyle") (hint-foreground text dark? center))
    (cons (string-append name "HintStyle")
          (object ["backgroundStyle" "alphabeticHintBackgroundStyle"]
                  ["foregroundStyle" (string-append name "HintForegroundStyle")]
                  ["size" hint-size])))))

(define (system-text-button spec dark?)
  (define name (system-button-spec-name spec))
  (define text (system-button-spec-text spec))
  (define action (system-button-spec-action spec))
  (define size (system-button-spec-size spec))
  (define bounds (system-button-spec-bounds spec))
  (append
   (list
    (cons name
          (append
           (list (cons "action" action)
                 (cons "backgroundStyle" "systemButtonBackgroundStyle"))
           (if bounds (list (cons "bounds" bounds)) '())
           (list (cons "foregroundStyle" (string-append name "ForegroundStyle"))
                 (cons "size" size)))))
   (list
    (cons (string-append name "ForegroundStyle")
          (object ["buttonStyleType" "text"]
                  ["fontSize" 16]
                  ["highlightColor" (theme-primary dark?)]
                  ["normalColor" (theme-primary dark?)]
                  ["text" text])))))

(define (backspace-button dark?)
  (list
   (cons "backspaceButton"
         (object ["action" "backspace"]
                 ["backgroundStyle" "systemButtonBackgroundStyle"]
                 ["bounds" right-system-bounds]
                 ["foregroundStyle" "backspaceButtonForegroundStyle"]
                 ["repeatAction" "backspace"]
                 ["size" system-width]))
   (cons "backspaceButtonForegroundStyle"
         (object ["buttonStyleType" "systemImage"]
                 ["fontSize" 20]
                 ["highlightColor" (theme-primary dark?)]
                 ["highlightSystemImageName" "delete.left.fill"]
                 ["normalColor" (theme-primary dark?)]
                 ["systemImageName" "delete.left"]))))

(define (space-button dark?)
  (list
   (cons "spaceButton"
         (object ["action" "space"]
                 ["backgroundStyle" "alphabeticButtonBackgroundStyle"]
                 ["foregroundStyle" "spaceButtonForegroundStyle"]
                 ["notification" (array "preeditChangedForSpaceButtonNotification")]
                 ["swipeUpAction" (shortcut-action "#次选上屏")]))
   (cons "spaceButtonForegroundStyle"
         (object ["buttonStyleType" "systemImage"]
                 ["fontSize" 20]
                 ["highlightColor" (theme-primary dark?)]
                 ["normalColor" (theme-primary dark?)]
                 ["systemImageName" "space"]))))

(define (expand-button dark?)
  (list
   (cons "expandButton"
         (object ["action" (shortcut-action "#candidatesBarStateToggle")]
                 ["foregroundStyle" "expandButtonForegroundStyle"]
                 ["size" (object ["width" 44])]))
   (cons "expandButtonForegroundStyle"
         (object ["buttonStyleType" "systemImage"]
                 ["fontSize" 20]
                 ["highlightColor" (theme-primary dark?)]
                 ["normalColor" (theme-primary dark?)]
                 ["systemImageName" "chevron.forward"]))))

(define (blue-button-foreground-style dark?)
  (list
   (cons "blueButtonForegroundStyle"
         (object ["buttonStyleType" "text"]
                 ["fontSize" 16]
                 ["highlightColor" (theme-primary dark?)]
                 ["normalColor" "#FFFFFF"]
                 ["text" "$returnKeyType"]))))

(define (enter-button dark?)
  (list
   (cons "enterButton"
         (object ["action" "enter"]
                 ["backgroundStyle"
                  (array
                   (object ["conditionKey" "$returnKeyType"]
                           ["conditionValue" (array 0 2 3 5 6 8 11)]
                           ["styleName" "systemButtonBackgroundStyle"])
                   (object ["conditionKey" "$returnKeyType"]
                           ["conditionValue" (array 1 4 7 9 10)]
                           ["styleName" "blueButtonBackgroundStyle"]))]
                 ["foregroundStyle"
                  (array
                   (object ["conditionKey" "$returnKeyType"]
                           ["conditionValue" (array 0 2 3 5 6 8 11)]
                           ["styleName" "enterButtonForegroundStyle"])
                   (object ["conditionKey" "$returnKeyType"]
                           ["conditionValue" (array 1 4 7 9 10)]
                           ["styleName" "blueButtonForegroundStyle"]))]
                 ["notification" (array "returnKeyTypeChangedNotification"
                                        "preeditChangedForEnterButtonNotification")]
                 ["size" large-system-width]))
   (cons "enterButtonForegroundStyle"
         (object ["buttonStyleType" "text"]
                 ["fontSize" 16]
                 ["highlightColor" (theme-primary dark?)]
                 ["normalColor" (theme-primary dark?)]
                 ["text" "$returnKeyType"]))))

(define (button-hash dark? button-specs system-button-specs keyboard-layout)
  (define (put entries base)
    (for/fold ([h base]) ([entry (in-list entries)])
      (hash-set h (car entry) (cdr entry))))
  (define h1
    (for/fold ([h (hash)]) ([spec (in-list button-specs)])
      (put (secondary-button spec dark?) h)))
  (define h2
    (for/fold ([h h1]) ([spec (in-list system-button-specs)])
      (put (system-text-button spec dark?) h)))
  (define h3 (put (backspace-button dark?) h2))
  (define h4 (put (space-button dark?) h3))
  (define h5 (put (expand-button dark?) h4))
  (define h6 (put (blue-button-foreground-style dark?) h5))
  (define h7 (put (enter-button dark?) h6))
  (hash-set h7 "keyboardLayout" keyboard-layout))

(define (ordered-page dark? portrait? base-page button-specs system-button-specs keyboard-layout)
  (define combined
    (hash-union (base-page dark? portrait?)
                (button-hash dark? button-specs system-button-specs keyboard-layout)
                #:combine/key (lambda (_ left _right) left)))
  (auto-ordered-page combined))

(define (make-phone-secondary-files
         #:portrait-name portrait-name
         #:landscape-name landscape-name
         #:base-page base-page
         #:button-specs button-specs
         #:system-buttons system-button-specs
         #:keyboard-layout keyboard-layout)
  (bundle
   (json-file (yaml-page "light" portrait-name)
              (ordered-page #f #t base-page button-specs system-button-specs keyboard-layout))
   (json-file (yaml-page "dark" portrait-name)
              (ordered-page #t #t base-page button-specs system-button-specs keyboard-layout))
   (json-file (yaml-page "light" landscape-name)
              (ordered-page #f #f base-page button-specs system-button-specs keyboard-layout))
   (json-file (yaml-page "dark" landscape-name)
              (ordered-page #t #f base-page button-specs system-button-specs keyboard-layout))))
