#lang racket/base

(require racket/list
         racket/string)

(provide parse-numberish
         preview-layout
         preview-key-role
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

(define control-preview-kinds
  '("backspace" "enter" "numeric" "space" "shift"))

(define control-preview-id-pattern
  #rx"(?i:backspace|delete|dismiss|emoji|enter|numeric|semicolon|shift|space|stroke[HSPNZ]Button)")

(define control-preview-labels
  '(";" "；"))

(define control-preview-icons
  '("delete.left" "delete.left.fill" "emojis" "face.smiling"
    "return" "shift" "shift.fill" "space" "space.fill"))

(define (preview-control-like-key? key)
  (or (member (hash-ref key 'kind "") control-preview-kinds)
      (regexp-match? control-preview-id-pattern (hash-ref key 'id ""))
      (member (hash-ref key 'label "") control-preview-labels)
      (member (hash-ref key 'icon "")
              control-preview-icons)))

(define (preview-key-role key)
  (cond
    [(hash-ref key 'spacer? #f) 'spacer]
    [(hash-ref key 'role #f)]
    [(preview-control-like-key? key) 'control]
    [else 'input]))

(define (preview-key-visible? key)
  (eq? (preview-key-role key) 'input))

(define (preview-visible-row preview row)
  (case (hash-ref preview 'visible-keys 'typing)
    [(all) row]
    [else (filter preview-key-visible? row)]))

(define (row-offsets-for rows raw-offsets)
  (define offsets
    (and (list? raw-offsets)
         (map (lambda (offset) (or (parse-numberish offset) 0)) raw-offsets)))
  (for/list ([row (in-list rows)]
             [index (in-naturals)])
    (if (and offsets (< index (length offsets)))
        (list-ref offsets index)
        0)))

(define (uniform-square-key-side width height rows row-offsets pad key-gap row-gap)
  (define row-count (max 1 (length rows)))
  (define key-height (/ (- height (* (+ row-count 1) row-gap)) row-count))
  (define inner-width (- width (* 2 pad)))
  (define max-extent
    (max preview-min-key-columns
         (for/fold ([extent 1])
                   ([row (in-list rows)]
                    [offset (in-list row-offsets)])
           (max extent (+ offset (length row))))))
  (define max-gap-extent
    (for/fold ([gap-extent (max 0 (sub1 preview-min-key-columns))])
              ([row (in-list rows)]
               [offset (in-list row-offsets)])
      (max gap-extent (+ offset (max 0 (sub1 (length row)))))))
  (max 1
       (min key-height
            (/ (- inner-width (* max-gap-extent key-gap))
               max-extent))))

(define (uniform-square-preview-layout width height rows row-offsets pad key-gap row-gap)
  (define row-count (max 1 (length rows)))
  (define key-side (uniform-square-key-side width height rows row-offsets pad key-gap row-gap))
  (define grid-height (+ (* row-count key-side)
                         (* (max 0 (sub1 row-count)) row-gap)))
  (define start-y (max row-gap (/ (- height grid-height) 2)))
  (for/list ([row (in-list rows)]
             [row-index (in-naturals)])
    (define y (+ start-y (* row-index (+ key-side row-gap))))
    (define row-gap-count (max 0 (sub1 (length row))))
    (define row-width (+ (* (length row) key-side)
                         (* row-gap-count key-gap)))
    (define row-offset (list-ref row-offsets row-index))
    (define start-x
      (if (for/or ([offset (in-list row-offsets)]) (not (zero? offset)))
          (+ pad (* row-offset (+ key-side key-gap)))
          (/ (- width row-width) 2)))
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

(define (preview-key-width-units key)
  (or (parse-numberish (hash-ref key 'width #f)) 1))

(define (preview-row-units row)
  (apply + (map preview-key-width-units row)))

(define (physical-square-key-side width height rows pad key-gap row-gap)
  (define row-count (max 1 (length rows)))
  (define key-height (/ (- height (* (+ row-count 1) row-gap)) row-count))
  (define inner-width (- width (* 2 pad)))
  (define max-units
    (for/fold ([units preview-min-key-columns])
              ([row (in-list rows)])
      (max units (preview-row-units row))))
  (define max-gap-count
    (for/fold ([gap-count (max 0 (sub1 preview-min-key-columns))])
              ([row (in-list rows)])
      (max gap-count (max 0 (sub1 (length row))))))
  (max 1
       (min key-height
            (/ (- inner-width (* max-gap-count key-gap))
               max-units))))

(define (physical-square-preview-layout width height rows pad key-gap row-gap)
  (define row-count (max 1 (length rows)))
  (define key-side (physical-square-key-side width height rows pad key-gap row-gap))
  (define grid-height (+ (* row-count key-side)
                         (* (max 0 (sub1 row-count)) row-gap)))
  (define start-y (max row-gap (/ (- height grid-height) 2)))
  (for/list ([row (in-list rows)]
             [row-index (in-naturals)])
    (define y (+ start-y (* row-index (+ key-side row-gap))))
    (define row-gap-count (max 0 (sub1 (length row))))
    (define row-width (+ (* (preview-row-units row) key-side)
                         (* row-gap-count key-gap)))
    (define start-x (/ (- width row-width) 2))
    (let loop ([keys row] [x start-x] [items '()])
      (cond
        [(null? keys) (reverse items)]
        [else
         (define key (car keys))
         (define key-width (* (preview-key-width-units key) key-side))
         (loop (cdr keys)
               (+ x key-width key-gap)
               (cons (hash 'key key
                           'x x
                           'y y
                           'width key-width
                           'height key-side)
                     items))]))))

(define (skin-proportional-preview-layout width height rows pad key-gap row-gap)
  (define row-count (max 1 (length rows)))
  (define key-height (/ (- height (* (+ row-count 1) row-gap)) row-count))
  (define inner-width (- width (* 2 pad)))
  (for/list ([row (in-list rows)]
             [row-index (in-naturals)])
    (define y (+ row-gap (* row-index (+ key-height row-gap))))
    (define row-gap-count (max 0 (sub1 (length row))))
    (define row-total-units (preview-row-units row))
    (define units (if (positive? row-total-units) row-total-units 1))
    (define unit-width (/ (- inner-width (* row-gap-count key-gap)) units))
    (let loop ([keys row] [x pad] [items '()])
      (cond
        [(null? keys) (reverse items)]
        [else
         (define key (car keys))
         (define width-units (preview-key-width-units key))
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
  (define row-offsets (row-offsets-for rows (hash-ref preview 'row-offsets '())))
  (case geometry
    [(skin-proportional)
     (skin-proportional-preview-layout width height rows pad key-gap row-gap)]
    [(physical-square)
     (physical-square-preview-layout width height rows pad key-gap row-gap)]
    [else
     (uniform-square-preview-layout width height rows row-offsets pad key-gap row-gap)]))
