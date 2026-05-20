#lang racket/base

(require "../core/dsl.rkt"
         "../core/visual-policy.rkt"
         "flypy18-page.rkt"
         "flypy18-bases.rkt"
         "phone-layout-rows.rkt")

(provide compact-14-key-size
         compact-14-keyboard-layout
         compact-14-base-page
         make-compact-14-files)

(define compact-14-key-size
  (square-key-size "225/1125"))

(define compact-14-keyboard-layout
  (array
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "qw14Button"])
                            (object ["Cell" "er14Button"])
                            (object ["Cell" "ty14Button"])
                            (object ["Cell" "ui14Button"])
                            (object ["Cell" "op14Button"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "as14Button"])
                            (object ["Cell" "df14Button"])
                            (object ["Cell" "gh14Button"])
                            (object ["Cell" "jk14Button"])
                            (object ["Cell" "l14Button"]))])])
   (object ["HStack"
            (object ["subviews"
                     (array (object ["Cell" "zx14Button"])
                            (object ["Cell" "cv14Button"])
                            (object ["Cell" "bn14Button"])
                            (object ["Cell" "m14Button"])
                            (object ["Cell" "backspaceButton"]))])])
   standard-pinyin-last-row))

(define (set-entry entry key value)
  (for/list ([pair (in-list entry)])
    (if (equal? (car pair) key)
        (cons key value)
        pair)))

(define (with-compact-14-system-sizes page)
  (hash-set page
            "backspaceButton"
            (set-entry (hash-ref page "backspaceButton")
                       "size"
                       compact-14-key-size)))

(define (compact-14-base-page dark? portrait?)
  (with-compact-14-system-sizes
   (cond
     [(and (not dark?) portrait?)       flypy18-portrait-light-base]
     [(and dark?       portrait?)       flypy18-portrait-dark-base]
     [(and (not dark?) (not portrait?)) flypy18-landscape-light-base]
     [else                              flypy18-landscape-dark-base])))

(define (make-compact-14-files #:button-specs button-specs
                               #:detail-font-size detail-font-size
                               #:label-center [label-center #f])
  (if label-center
      (make-flypy18-files
       #:portrait-name "pinyinPortrait"
       #:landscape-name "pinyinLandscape"
       #:base-page compact-14-base-page
       #:keyboard-layout compact-14-keyboard-layout
       #:button-specs button-specs
       #:detail-font-size detail-font-size
       #:label-center label-center)
      (make-flypy18-files
       #:portrait-name "pinyinPortrait"
       #:landscape-name "pinyinLandscape"
       #:base-page compact-14-base-page
       #:keyboard-layout compact-14-keyboard-layout
       #:button-specs button-specs
       #:detail-font-size detail-font-size)))
