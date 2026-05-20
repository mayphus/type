#lang racket/base

(require racket/hash
         racket/list
         racket/string
         "../core/dsl.rkt"
         "../core/builders.rkt"
         "../core/visual-policy.rkt"
         "base-page.rkt"
         "../keysets/pinyin-common.rkt")

(provide merged18-spec
         make-flypy18-files
         seven-column-size
         six-column-size
         side-inset-size
         side-inset-right-bounds
         side-inset-left-bounds)

(struct merged18-spec (name base-letter label hint size bounds swipe-down-action) #:transparent)

(define seven-column-size
  (square-key-size "160.7142857143/1125"))

(define six-column-size
  (square-key-size "160/1125"))

(define side-inset-size
  (square-key-size "242.5/1125" "160/1125"))

(define side-inset-right-bounds
  (object ["alignment" "right"]
          ["width" "160/242.5"]))

(define side-inset-left-bounds
  (object ["alignment" "left"]
          ["width" "160/242.5"]))

(define main-center
  (key-note-position 'center))

(define hint-center
  (key-note-position 'bottom))

(define top-center
  (key-note-position 'top))

(define (label-text-style dark? text center)
  (object ["buttonStyleType" "text"]
          ["center" center]
          ["fontSize" 18]
          ["fontWeight" "medium"]
          ["highlightColor" (theme-primary dark?)]
          ["normalColor" (theme-primary dark?)]
          ["text" text]))

(define (secondary-text-style dark? text center font-size)
  (object ["buttonStyleType" "text"]
          ["center" center]
          ["fontSize" font-size]
          ["highlightColor" (theme-secondary dark?)]
          ["normalColor" (theme-secondary dark?)]
          ["text" text]))

(define (hint-foreground-style dark? text)
  (object ["buttonStyleType" "text"]
          ["fontSize" 18]
          ["normalColor" (theme-primary dark?)]
          ["text" text]))

(define (style-array prefix)
  (array (string-append prefix "MainForegroundStyle")
         (string-append prefix "TopSymbolForegroundStyle")
         (string-append prefix "DetailForegroundStyle")))

(define (uppercase-style-array prefix)
  (array (string-append prefix "MainUppercaseForegroundStyle")
         (string-append prefix "TopSymbolForegroundStyle")
         (string-append prefix "DetailForegroundStyle")))

(define (merged-button-entries dark? spec detail-font-size label-center)
  (define prefix (merged18-spec-name spec))
  (define base-spec (find-hybrid-letter-spec (merged18-spec-base-letter spec)))
  (define swipe-down-action
    (or (merged18-spec-swipe-down-action spec)
        (key-spec-swipe-down base-spec)))
  (define button
    (append
     (list (cons "action" (char-action (merged18-spec-base-letter spec)))
           (cons "backgroundStyle" "alphabeticButtonBackgroundStyle"))
     (if (merged18-spec-bounds spec)
         (list (cons "bounds" (merged18-spec-bounds spec)))
         '())
     (list (cons "capsLockedStateForegroundStyle" (uppercase-style-array prefix))
           (cons "foregroundStyle" (style-array prefix))
           (cons "hintStyle" (string-append prefix "HintStyle"))
           (cons "size" (merged18-spec-size spec)))
     (if swipe-down-action
         (list (cons "swipeDownAction" swipe-down-action))
         '())
     (list (cons "swipeUpAction" (key-spec-swipe-up base-spec))
           (cons "uppercasedStateAction" (char-action (string-upcase (merged18-spec-base-letter spec))))
           (cons "uppercasedStateForegroundStyle" (uppercase-style-array prefix)))))
  (list
   (cons prefix button)
   (cons (string-append prefix "MainForegroundStyle")
         (label-text-style dark? (merged18-spec-label spec) label-center))
   (cons (string-append prefix "MainUppercaseForegroundStyle")
         (label-text-style dark? (string-upcase (merged18-spec-label spec)) label-center))
   (cons (string-append prefix "TopSymbolForegroundStyle")
         (secondary-text-style dark? (key-spec-symbol base-spec) top-center 9))
   (cons (string-append prefix "DetailForegroundStyle")
         (secondary-text-style dark? (merged18-spec-hint spec) hint-center detail-font-size))
   (cons (string-append prefix "HintForegroundStyle")
         (hint-foreground-style dark? (merged18-spec-label spec)))
   (cons (string-append prefix "HintStyle")
         (object ["backgroundStyle" "alphabeticHintBackgroundStyle"]
                 ["foregroundStyle" (string-append prefix "HintForegroundStyle")]))))

(define (make-flypy18-files
         #:portrait-name portrait-name
         #:landscape-name landscape-name
         #:base-page base-page
         #:keyboard-layout keyboard-layout
         #:button-specs button-specs
         #:detail-font-size detail-font-size
         #:label-center [label-center main-center])
  (define (page-builder dark? portrait?)
    (make-grid-page dark? portrait?
                    #:base-page-builder base-page
                    #:keyboard-layout keyboard-layout
                    #:button-specs button-specs
                    #:button-renderer (lambda (d s) (merged-button-entries d s detail-font-size label-center))))
  (make-pinyin-bundle portrait-name landscape-name page-builder))
