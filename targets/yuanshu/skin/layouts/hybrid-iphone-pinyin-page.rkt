#lang racket/base

(require racket/hash
         "../core/dsl.rkt"
         "../core/visual-policy.rkt"
         "../keysets/pinyin-common.rkt"
         "base-page.rkt"
         "standard-phone-pinyin-page.rkt")

(define (hybrid-phone-base dark? portrait?)
  (make-phone-base-page dark? portrait?
                        #:keyboard-height (if portrait? "216" "160")))

(define iphone-pinyin-portrait-light-base  (hybrid-phone-base #f #t))
(define iphone-pinyin-portrait-dark-base   (hybrid-phone-base #t #t))
(define iphone-pinyin-landscape-light-base (hybrid-phone-base #f #f))
(define iphone-pinyin-landscape-dark-base  (hybrid-phone-base #t #f))

(provide iphone-pinyin-files)

(define normal-button-size
  (square-key-size "112.5/1125"))

(define hint-size
  (object ["height" 50]
          ["width" 50]))

(define iphone-letter-config
  (hash
   'size-for (lambda (_spec)
               (values normal-button-size #f '()))
   'abc-font-size (json-number "10.5")
   'cangjie-font-size (json-number "15.5")
   'symbol-font-size (json-number "8.5")
   'flypy-single-font-size 12
   'flypy-double-font-size (json-number "7.25")
   'hint-style-extra (list (cons "size" hint-size))))

(define (base-page dark? portrait?)
  (cond
    [(and (not dark?) portrait?) iphone-pinyin-portrait-light-base]
    [(and dark? portrait?) iphone-pinyin-portrait-dark-base]
    [(and (not dark?) (not portrait?)) iphone-pinyin-landscape-light-base]
    [else iphone-pinyin-landscape-dark-base]))

(define (ordered-page dark? portrait?)
  (define combined
    (hash-union (base-page dark? portrait?)
                (hash-set
                 (make-letter-entry-hash dark? hybrid-letter-specs iphone-letter-config)
                 "keyboardLayout"
                 standard-phone-keyboard-layout)
                #:combine/key (lambda (_ left _right) left)))
  (auto-ordered-page combined))

(define iphone-pinyin-files
  (bundle
   (json-file (yaml-page "light" "pinyinPortrait") (ordered-page #f #t))
   (json-file (yaml-page "dark" "pinyinPortrait") (ordered-page #t #t))
   (json-file (yaml-page "light" "pinyinLandscape") (ordered-page #f #f))
   (json-file (yaml-page "dark" "pinyinLandscape") (ordered-page #t #f))))
