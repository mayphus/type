#lang racket/base

(require "../core/dsl.rkt"
         "../core/visual-policy.rkt"
         "flypy18-page.rkt"
         "flypy18-bases.rkt"
         "phone-layout-rows.rkt")

(provide compact-9-key-size
         compact-9-keyboard-layout
         compact-9-base-page
         make-compact-9-files)

(define compact-9-key-size
  (square-key-size "375/1125"))

(define compact-9-keyboard-layout
  (array
   (keyboard-layout-row '("qwe9Button" "rty9Button" "uiop9Button"))
   (keyboard-layout-row '("asd9Button" "fgh9Button" "jkl9Button"))
   (keyboard-layout-row '("zxc9Button" "vbn9Button" "m9Button"))
   standard-pinyin-last-row))

(define (compact-9-base-page dark? portrait?)
  (cond
    [(and (not dark?) portrait?)       flypy18-portrait-light-base]
    [(and dark?       portrait?)       flypy18-portrait-dark-base]
    [(and (not dark?) (not portrait?)) flypy18-landscape-light-base]
    [else                              flypy18-landscape-dark-base]))

(define (make-compact-9-files #:button-specs button-specs
                              #:detail-font-size detail-font-size
                              #:label-center [label-center #f])
  (if label-center
      (make-flypy18-files
       #:portrait-name "pinyinPortrait"
       #:landscape-name "pinyinLandscape"
       #:base-page compact-9-base-page
       #:keyboard-layout compact-9-keyboard-layout
       #:button-specs button-specs
       #:detail-font-size detail-font-size
       #:label-center label-center)
      (make-flypy18-files
       #:portrait-name "pinyinPortrait"
       #:landscape-name "pinyinLandscape"
       #:base-page compact-9-base-page
       #:keyboard-layout compact-9-keyboard-layout
       #:button-specs button-specs
       #:detail-font-size detail-font-size)))
