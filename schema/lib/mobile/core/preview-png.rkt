#lang racket/base

(require racket/draw
         racket/class
         racket/file
         racket/match
         "preview.rkt")

(provide demo-preview-png-bytes)

(define demo-width 996)
(define demo-height 660)
(define keyboard-pad 8)
(define key-gap 4)
(define row-gap 6)

(define (numberish value fallback)
  (cond
    [(number? value) value]
    [(string? value) (or (string->number value) fallback)]
    [else fallback]))

(define (hash-get h key fallback)
  (if (hash? h) (hash-ref h key fallback) fallback))

(define (color-components color)
  (and (string? color)
       (regexp-match #px"^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$" color)))

(define (hex-byte color start)
  (string->number (substring color start (+ start 2)) 16))

(define (rgba color fallback)
  (match (color-components color)
    [(list _ rgb alpha)
     (make-object color%
       (hex-byte rgb 0)
       (hex-byte rgb 2)
       (hex-byte rgb 4)
       (if alpha (/ (hex-byte alpha 0) 255.0) 1.0))]
    [_ (rgba fallback "#000000")]))

(define (color-bright? color)
  (match (color-components color)
    [(list _ rgb _alpha)
     (define r (hex-byte rgb 0))
     (define g (hex-byte rgb 2))
     (define b (hex-byte rgb 4))
     (> (+ (* 0.2126 r) (* 0.7152 g) (* 0.0722 b)) 155)]
    [_ #t]))

(define (fallback-color background)
  (if (color-bright? background) "#111111" "#ffffff"))

(define (key-stroke-color background)
  (if (color-bright? background) "#00000022" "#ffffff28"))

(define (font-weight-symbol weight)
  (cond
    [(equal? weight "bold") 'bold]
    [(equal? weight "semibold") 'semibold]
    [(equal? weight "medium") 'medium]
    [(equal? weight "700") 'bold]
    [(equal? weight "600") 'semibold]
    [(equal? weight "500") 'medium]
    [else 'normal]))

(define (font size weight)
  (make-font #:size (max 1 size)
             #:family 'default
             #:weight (font-weight-symbol weight)))

(define (draw-centered-text dc text cx cy size weight color)
  (send dc set-font (font size weight))
  (send dc set-text-foreground (rgba color "#111111"))
  (define-values (tw th _descent _space) (send dc get-text-extent text))
  (send dc draw-text text (- cx (/ tw 2)) (- cy (/ th 2))))

(define (draw-line dc color width points)
  (send dc set-pen (new pen% [color (rgba color "#111111")] [width width] [cap 'round] [join 'round]))
  (for ([a (in-list points)]
        [b (in-list (cdr points))])
    (send dc draw-line (car a) (cdr a) (car b) (cdr b))))

(define (draw-space dc x y width height color)
  (define icon-width (min (* width 0.2) 28))
  (define icon-height (min (* height 0.28) 12))
  (define left (+ x (/ (- width icon-width) 2)))
  (define right (+ left icon-width))
  (define top (+ y (/ (- height icon-height) 2)))
  (define bottom (+ top icon-height))
  (draw-line dc color 1.7 (list (cons left top) (cons left bottom) (cons right bottom) (cons right top))))

(define (draw-shift dc cx cy color)
  (draw-line dc color 1.9
             (list (cons (- cx 10) (+ cy 1))
                   (cons cx (- cy 10))
                   (cons (+ cx 10) (+ cy 1))))
  (draw-line dc color 1.9
             (list (cons cx (- cy 10))
                   (cons cx (+ cy 12)))))

(define (draw-backspace dc cx cy color)
  (draw-line dc color 1.9
             (list (cons (- cx 14) cy)
                   (cons (- cx 5) (- cy 9))
                   (cons (+ cx 14) (- cy 9))
                   (cons (+ cx 14) (+ cy 9))
                   (cons (- cx 5) (+ cy 9))
                   (cons (- cx 14) cy)))
  (draw-line dc color 1.9
             (list (cons (- cx 2) (- cy 4))
                   (cons (+ cx 6) (+ cy 4))))
  (draw-line dc color 1.9
             (list (cons (+ cx 6) (- cy 4))
                   (cons (- cx 2) (+ cy 4)))))

(define (draw-face dc cx cy width height icon-size color)
  (define r (min (* icon-size 0.5) (* width 0.32) (* height 0.34)))
  (define scale (/ r 12))
  (send dc set-brush (new brush% [style 'transparent]))
  (send dc set-pen (new pen% [color (rgba color "#111111")] [width 1.9]))
  (send dc draw-ellipse (- cx r) (- cy r) (* 2 r) (* 2 r))
  (send dc set-brush (new brush% [color (rgba color "#111111")]))
  (send dc set-pen (new pen% [color (rgba color "#111111")] [width 1]))
  (send dc draw-ellipse (- cx (* 5.55 scale)) (- cy (* 4.55 scale)) (* 2.7 scale) (* 2.7 scale))
  (send dc draw-ellipse (+ cx (* 2.85 scale)) (- cy (* 4.55 scale)) (* 2.7 scale) (* 2.7 scale))
  (send dc set-brush (new brush% [style 'transparent]))
  (send dc set-pen (new pen% [color (rgba color "#111111")] [width 1.8] [cap 'round]))
  (define path (new dc-path%))
  (send path move-to (- cx (* 5.5 scale)) (+ cy (* 3.2 scale)))
  (send path curve-to (- cx (* 2.5 scale)) (+ cy (* 6.4 scale)) (+ cx (* 2.5 scale)) (+ cy (* 6.4 scale)) (+ cx (* 5.5 scale)) (+ cy (* 3.2 scale)))
  (send dc draw-path path))

(define (draw-special dc key x y width height)
  (define color (fallback-color (hash-get key 'background "#ffffff")))
  (define kind (hash-get key 'kind ""))
  (define icon (hash-get key 'icon ""))
  (define icon-size (numberish (hash-get key 'icon-size 20) 20))
  (define cx (+ x (/ width 2)))
  (define cy (+ y (/ height 2)))
  (cond
    [(or (equal? kind "space") (equal? icon "space")) (draw-space dc x y width height color)]
    [(or (equal? kind "shift") (member icon '("shift" "shift.fill" "capslock.fill"))) (draw-shift dc cx cy color)]
    [(or (equal? kind "backspace") (member icon '("delete.left" "delete.left.fill"))) (draw-backspace dc cx cy color)]
    [(member icon '("face.smiling" "emojis")) (draw-face dc cx cy width height icon-size color)]
    [else
     (define label
       (or (and (not (equal? (hash-get key 'label "") "")) (hash-get key 'label ""))
           (and (equal? kind "numeric") "123")
           (and (equal? kind "enter") "↵")
           icon))
     (when (and (string? label) (not (string=? label "")))
       (draw-centered-text dc label cx cy (if (equal? kind "numeric") 16 18) "medium" color))]))

(define (draw-layer dc layer x y width height scale)
  (define text (hash-get layer 'text ""))
  (when (and (string? text) (not (string=? text "")))
    (define lx (+ x (* (numberish (hash-get layer 'x 0.5) 0.5) width)))
    (define ly (+ y (* (numberish (hash-get layer 'y 0.5) 0.5) height)))
    (define size (max 9 (* scale (numberish (hash-get layer 'font-size 14) 14))))
    (draw-centered-text dc text lx ly size (hash-get layer 'font-weight "") (hash-get layer 'color "#111111"))))

(define (draw-key dc key x y width height)
  (define background (hash-get key 'background "#ffffff"))
  (send dc set-brush (new brush% [color (rgba background "#ffffff")]))
  (send dc set-pen (new pen% [color (rgba (key-stroke-color background) "#00000022")] [width 0.75]))
  (send dc draw-rounded-rectangle x y width height 8)
  (define layers (hash-get key 'layers '()))
  (if (and (list? layers) (pair? layers))
      (for ([layer (in-list layers)])
        (draw-layer dc layer x y width height 1.02))
      (draw-special dc key x y width height)))

(define (draw-keyboard dc preview)
  (define size (hash-get preview 'size (hash)))
  (define width (numberish (hash-get size 'width 375) 375))
  (define height (numberish (hash-get size 'height 216) 216))
  (define background (hash-get preview 'background "#f2f3f7"))
  (send dc set-brush (new brush% [color (rgba background "#f2f3f7")]))
  (send dc set-pen (new pen% [color (rgba background "#f2f3f7")] [width 0]))
  (send dc draw-rounded-rectangle 0 0 width height 18)
  (for* ([row (in-list (preview-layout preview
                                       #:pad keyboard-pad
                                       #:key-gap key-gap
                                       #:row-gap row-gap))]
         [item (in-list row)])
    (define key (hash-get item 'key #f))
    (when (preview-key-visible? key)
      (draw-key dc
                key
                (hash-get item 'x 0)
                (hash-get item 'y 0)
                (hash-get item 'width 0)
                (hash-get item 'height 0)))))

(define (light-preview preview-spec)
  (if (and (hash? preview-spec) (hash-has-key? preview-spec 'dark))
      (hash-remove preview-spec 'dark)
      preview-spec))

(define (demo-preview-png-bytes title preview-spec)
  (define preview (light-preview preview-spec))
  (define size (hash-get preview 'size (hash)))
  (define logical-width (numberish (hash-get size 'width 375) 375))
  (define logical-height (numberish (hash-get size 'height 216) 216))
  (define keyboard-x 68)
  (define keyboard-y 120)
  (define keyboard-width 860)
  (define keyboard-height 482)
  (define scale (min (/ keyboard-width logical-width) (/ keyboard-height logical-height)))
  (define scaled-width (* logical-width scale))
  (define scaled-height (* logical-height scale))
  (define offset-x (+ keyboard-x (/ (- keyboard-width scaled-width) 2)))
  (define offset-y (+ keyboard-y (/ (- keyboard-height scaled-height) 2)))
  (define bitmap (make-object bitmap% demo-width demo-height #f #t))
  (define dc (new bitmap-dc% [bitmap bitmap]))
  (send dc set-smoothing 'smoothed)
  (send dc set-brush (new brush% [color (rgba "#F6F7FA" "#F6F7FA")]))
  (send dc set-pen (new pen% [color (rgba "#F6F7FA" "#F6F7FA")] [width 0]))
  (send dc draw-rectangle 0 0 demo-width demo-height)
  (send dc set-brush (new brush% [color (rgba "#ECEEF4" "#ECEEF4")]))
  (send dc set-pen (new pen% [color (rgba "#D7D9E1" "#D7D9E1")] [width 1]))
  (send dc draw-rounded-rectangle 42 36 912 588 42)
  (draw-centered-text dc title 498 82 38 "bold" "#202124")
  (define old-transform (send dc get-transformation))
  (send dc translate offset-x offset-y)
  (send dc scale scale scale)
  (draw-keyboard dc preview)
  (send dc set-transformation old-transform)
  (send dc set-bitmap #f)
  (define path (make-temporary-file "yuanshu-demo-~a.png"))
  (dynamic-wind
    void
    (lambda ()
      (send bitmap save-file path 'png)
      (file->bytes path))
    (lambda ()
      (when (file-exists? path)
        (delete-file path)))))
