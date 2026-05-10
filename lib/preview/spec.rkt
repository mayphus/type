#lang racket/base

(require racket/list
         racket/string)

(provide parse-numberish
         preview-layout
         preview-key-visible?)

(define preview-min-key-columns 10)

(define (parse-numberish value)
  (cond
    [(number? value) value]
    [(string? value)
     (define parts (string-split value "/"))
     (cond
       [(= (length parts) 2)
        (define numerator (string->number (first parts)))
        (define denominator (string->number (second parts)))
        (and numerator denominator (not (zero? denominator))
             (exact->inexact (/ numerator denominator)))]
       [else (string->number value)])]
    [else #f]))

(define hidden-preview-kinds
  '("backspace" "enter" "numeric" "space" "shift"))

(define hidden-preview-id-pattern
  #rx"(?i:backspace|delete|dismiss|emoji|enter|numeric|semicolon|shift|space|stroke[HSPNZ]Button)")

(define hidden-preview-labels
  '(";" "；"))

(define (preview-control-key? key)
  (or (member (hash-ref key 'kind "") hidden-preview-kinds)
      (regexp-match? hidden-preview-id-pattern (hash-ref key 'id ""))
      (member (hash-ref key 'label "") hidden-preview-labels)
      (member (hash-ref key 'icon "")
              '("delete.left" "delete.left.fill" "emojis" "face.smiling"
                "return" "shift" "shift.fill" "space" "space.fill"))))

(define (preview-key-visible? key)
  (and (not (hash-ref key 'spacer? #f))
       (not (preview-control-key? key))))

(define (preview-visible-row preview row)
  (case (hash-ref preview 'visible-keys 'typing)
    [(all) row]
    [else (filter preview-key-visible? row)]))

(define (uniform-square-preview-layout width height rows pad key-gap row-gap)
  (define row-count (max 1 (length rows)))
  (define key-height (/ (- height (* (+ row-count 1) row-gap)) row-count))
  (define max-columns
    (max preview-min-key-columns
         (apply max 1 (map length rows))))
  (define key-side
    (max 1
         (min key-height
              (/ (- width (* 2 pad) (* (max 0 (sub1 max-columns)) key-gap))
                 max-columns))))
  (define grid-height (+ (* row-count key-side)
                         (* (max 0 (sub1 row-count)) row-gap)))
  (define start-y (max row-gap (/ (- height grid-height) 2)))
  (for/list ([row (in-list rows)]
             [row-index (in-naturals)])
    (define y (+ start-y (* row-index (+ key-side row-gap))))
    (define row-gap-count (max 0 (sub1 (length row))))
    (define row-width (+ (* (length row) key-side)
                         (* row-gap-count key-gap)))
    (define start-x (/ (- width row-width) 2))
    (let loop ([keys row] [x start-x] [items '()])
      (cond
        [(null? keys) (reverse items)]
        [else
         (define key (car keys))
         (loop (cdr keys)
               (+ x key-side key-gap)
               (cons (hash 'key key
                           'x x
                           'y y
                           'width key-side
                           'height key-side)
                     items))]))))

(define (skin-proportional-preview-layout width height rows pad key-gap row-gap)
  (define row-count (max 1 (length rows)))
  (define key-height (/ (- height (* (+ row-count 1) row-gap)) row-count))
  (define inner-width (- width (* 2 pad)))
  (define (row-units row)
    (apply + (map (lambda (key)
                    (or (parse-numberish (hash-ref key 'width #f)) 1))
                  row)))
  (for/list ([row (in-list rows)]
             [row-index (in-naturals)])
    (define y (+ row-gap (* row-index (+ key-height row-gap))))
    (define row-gap-count (max 0 (sub1 (length row))))
    (define row-total-units (row-units row))
    (define units (if (positive? row-total-units) row-total-units 1))
    (define unit-width (/ (- inner-width (* row-gap-count key-gap)) units))
    (let loop ([keys row] [x pad] [items '()])
      (cond
        [(null? keys) (reverse items)]
        [else
         (define key (car keys))
         (define width-units (or (parse-numberish (hash-ref key 'width #f)) 1))
         (define key-width (* width-units unit-width))
         (loop (cdr keys)
               (+ x key-width key-gap)
               (cons (hash 'key key
                           'x x
                           'y y
                           'width key-width
                           'height key-height)
                     items))]))))

(define (preview-layout preview
                        #:pad [pad 8]
                        #:key-gap [key-gap 4]
                        #:row-gap [row-gap 6]
                        #:geometry [geometry 'uniform-square])
  (define size (hash-ref preview 'size (hash)))
  (define width (parse-numberish (hash-ref size 'width 375)))
  (define height (parse-numberish (hash-ref size 'height 216)))
  (define rows
    (filter pair?
            (map (lambda (row) (preview-visible-row preview row))
                 (hash-ref preview 'rows '()))))
  (case geometry
    [(skin-proportional)
     (skin-proportional-preview-layout width height rows pad key-gap row-gap)]
    [else
     (uniform-square-preview-layout width height rows pad key-gap row-gap)]))
