#lang racket/base

(require racket/format
         racket/hash
         racket/list
         racket/string
         "../../../input-method/keyboard/catalog.rkt"
         "../core/dsl.rkt"
         "../core/visual-policy.rkt"
         "../keysets/pinyin-common.rkt"
         "base-page.rkt"
         "phone-layout-rows.rkt")

(provide make-flypy-phone-files
         make-cangjie6-phone-files
         make-standard-phone-pinyin-files
         button-size+bounds
         hint-size
         standard-phone-keyboard-layout
         phone-legend-centers
         standard-phone-portrait-light-base
         standard-phone-portrait-dark-base
         standard-phone-landscape-light-base
         standard-phone-landscape-dark-base)

(define (standard-phone-base dark? portrait?)
  (make-phone-base-page dark? portrait?
                        #:keyboard-height (if portrait? "216" "160")))

(define standard-phone-portrait-light-base  (standard-phone-base #f #t))
(define standard-phone-portrait-dark-base   (standard-phone-base #t #t))
(define standard-phone-landscape-light-base (standard-phone-base #f #f))
(define standard-phone-landscape-dark-base  (standard-phone-base #t #f))

(define standard-phone-model
  (keyboard-model-definition-ref 'standard-26))

(define (model-clause name)
  (define clause (assoc name standard-phone-model))
  (and clause (cdr clause)))

(define standard-phone-columns
  (car (or (model-clause 'columns)
           (error 'standard-phone-columns "missing standard-26 columns"))))

(define (trim-decimal s)
  (regexp-replace #rx"\\.$"
                  (regexp-replace #rx"0+$" s "")
                  ""))

(define (model-width units)
  (format "~a/1125"
          (trim-decimal
           (real->decimal-string (/ (* 1125 units) standard-phone-columns) 4))))

(define normal-button-size
  (square-key-size (model-width 1)))

(define middle-row-spacer-size
  (object ["width" (model-width 1/2)]))

(define middle-row-spacer-entries
  (hash "middleRowLeftSpacer"
        (object ["size" middle-row-spacer-size])
        "middleRowRightSpacer"
        (object ["size" middle-row-spacer-size])))

(define third-row-spacer-size
  (object ["width" (model-width 1/2)]))

(define third-row-spacer-entries
  (hash "thirdRowLeftSpacer"
        (object ["size" third-row-spacer-size])
        "thirdRowRightSpacer"
        (object ["size" third-row-spacer-size])))

(define hint-size
  (object ["height" 50]
          ["width" 50]))

(define (letter-id key)
  (string-append (symbol->string key) "Button"))

(define (row-spacer-id row-index side)
  (case row-index
    [(1) (if (eq? side 'left) "middleRowLeftSpacer" "middleRowRightSpacer")]
    [else (format "row~a~aSpacer"
                  row-index
                  (if (eq? side 'left) "Left" "Right"))]))

(define (keyboard-layout-rows rows row-offsets)
  (list->vector
   (for/list ([row (in-list rows)]
              [offset (in-list row-offsets)]
              [row-index (in-naturals)])
     (define letter-ids (map letter-id row))
     (define ids
       (case row-index
         [(2) (append (list "shiftButton" "thirdRowLeftSpacer")
                      letter-ids
                      (list "thirdRowRightSpacer" "backspaceButton"))]
         [else
          (append
           (if (and (number? offset) (positive? offset))
               (list (row-spacer-id row-index 'left))
               '())
           letter-ids
           (if (and (number? offset) (positive? offset))
               (list (row-spacer-id row-index 'right))
               '()))]))
     (keyboard-layout-row ids))))

(define standard-phone-letter-layout-rows
  (keyboard-layout-rows
   (or (model-clause 'rows)
       (error 'standard-phone-keyboard-layout "missing standard-26 rows"))
   (or (model-clause 'row-offsets)
       (error 'standard-phone-keyboard-layout "missing standard-26 row offsets"))))

(define standard-phone-keyboard-layout
  (list->vector
   (append (vector->list standard-phone-letter-layout-rows)
           (list (keyboard-layout-row
                  '("numericButton" "spaceButton" "enterButton"))))))

(define phone-legend-centers
  (hash 'abc (key-note-position 'top)
        'flypy-single (key-note-position 'bottom)
        'flypy-top (key-note-position 'center)
        'flypy-bottom (key-note-position 'bottom)
        'cangjie (key-note-position 'center)
        'symbol (key-note-position 'top-right)))

(define (button-size+bounds spec)
  (values normal-button-size #f '()))

(define (make-phone-letter-config layers)
  (hash
   'enabled-layers layers
   'size-for button-size+bounds
   'centers phone-legend-centers
   'abc-font-size 10
   'abc-secondary? #t
   'cangjie-font-size 14
   'symbol-font-size 10
   'flypy-single-font-size (json-number "13.5")
   'flypy-double-font-size 10
   'hint-style-extra (list (cons "size" hint-size))))

(define (ordered-page base-page letter-builder dark? portrait?)
  (define combined
    (hash-union (base-page dark? portrait?)
                middle-row-spacer-entries
                third-row-spacer-entries
                (hash-set (letter-builder dark?) "keyboardLayout" standard-phone-keyboard-layout)
                #:combine/key (lambda (_ left _right) left)))
  (auto-ordered-page combined))

(define (make-standard-phone-files base-page letter-builder)
  (bundle
   (json-file (yaml-page "light" "pinyinPortrait")
              (ordered-page base-page letter-builder #f #t))
   (json-file (yaml-page "dark" "pinyinPortrait")
              (ordered-page base-page letter-builder #t #t))
   (json-file (yaml-page "light" "pinyinLandscape")
              (ordered-page base-page letter-builder #f #f))
   (json-file (yaml-page "dark" "pinyinLandscape")
              (ordered-page base-page letter-builder #t #f))))

(define (make-standard-phone-pinyin-files base-page letter-config)
  (make-standard-phone-files
   base-page
   (lambda (dark?) (make-letter-entry-hash dark? hybrid-letter-specs letter-config))))

(define (make-flypy-phone-files base-page)
  (define config (make-phone-letter-config '(abc flypy)))
  (make-standard-phone-pinyin-files base-page config))

(define (make-cangjie6-phone-files base-page)
  (define config (make-phone-letter-config '(cangjie)))
  (make-standard-phone-pinyin-files base-page config))
