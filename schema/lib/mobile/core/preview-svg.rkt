#lang racket/base

(require racket/format
         racket/match
         racket/string)

(provide keyboard-preview-svg
         demo-preview-svg
         preview-spec->svgs)

(define demo-width 996)
(define demo-height 660)
(define keyboard-pad 8)
(define key-gap 4)
(define row-gap 6)

(define (attr-escape value)
  (define s (~a value))
  (string-replace
   (string-replace
    (string-replace
     (string-replace
      (string-replace s "&" "&amp;")
      "\"" "&quot;")
     "<" "&lt;")
    ">" "&gt;")
   "'" "&apos;"))

(define (text-escape value)
  (define s (~a value))
  (string-replace
   (string-replace
    (string-replace s "&" "&amp;")
    "<" "&lt;")
   ">" "&gt;"))

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

(define (fill-attrs color fallback)
  (match (color-components color)
    [(list _ rgb alpha)
     (define opacity
       (and alpha (/ (string->number alpha 16) 255.0)))
     (format "fill=\"#~a\"~a"
             rgb
             (if opacity
                 (format " fill-opacity=\"~a\"" (real->decimal-string opacity 3))
                 ""))]
    [_ (format "fill=\"~a\"" (attr-escape fallback))]))

(define (color-bright? color)
  (match (color-components color)
    [(list _ rgb _alpha)
     (define r (hex-byte rgb 0))
     (define g (hex-byte rgb 2))
     (define b (hex-byte rgb 4))
     (> (+ (* 0.2126 r) (* 0.7152 g) (* 0.0722 b)) 155)]
    [_ #t]))

(define (key-stroke-color background)
  (if (color-bright? background) "#00000016" "#ffffff22"))

(define (stroke-attrs color width)
  (format "stroke=\"~a\" stroke-width=\"~a\""
          (attr-escape color)
          (real->decimal-string width 2)))

(define (hex-byte color start)
  (string->number (substring color start (+ start 2)) 16))

(define (fallback-color background)
  (match (color-components background)
    [(list _ rgb _alpha)
     (define r (hex-byte rgb 0))
     (define g (hex-byte rgb 2))
     (define b (hex-byte rgb 4))
     (if (> (+ (* 0.2126 r) (* 0.7152 g) (* 0.0722 b)) 155)
         "#111111"
         "#ffffff")]
    [_ "#111111"]))

(define (special-label key)
  (define label (hash-get key 'label ""))
  (cond
    [(and (string? label) (not (string=? label ""))) label]
    [else
     (match (hash-get key 'kind "")
       ["shift" "⇧"]
       ["backspace" "⌫"]
       ["enter" "↵"]
       ["space" "space"]
       ["numeric" "123"]
       [_ (hash-get key 'icon "")])]))

(define (font-weight layer)
  (define weight (hash-get layer 'font-weight "400"))
  (cond
    [(equal? weight "bold") "700"]
    [(equal? weight "semibold") "600"]
    [(equal? weight "medium") "500"]
    [(and (string? weight) (not (string=? weight ""))) weight]
    [else "400"]))

(define (text-layer-svg layer x y width height scale)
  (define text (hash-get layer 'text ""))
  (if (or (not (string? text)) (string=? text ""))
      ""
      (let* ([lx (+ x (* (numberish (hash-get layer 'x 0.5) 0.5) width))]
             [ly (+ y (* (numberish (hash-get layer 'y 0.5) 0.5) height))]
             [font-size (max 9 (* scale (numberish (hash-get layer 'font-size 14) 14)))]
             [color (hash-get layer 'color "#111111")])
        (format "<text x=\"~a\" y=\"~a\" text-anchor=\"middle\" dominant-baseline=\"central\" font-family=\"Avenir Next, SF Pro Display, Segoe UI, Noto Sans, PingFang TC, sans-serif\" font-size=\"~a\" font-weight=\"~a\" ~a>~a</text>"
                (real->decimal-string lx 2)
                (real->decimal-string ly 2)
                (real->decimal-string font-size 2)
                (attr-escape (font-weight layer))
                (fill-attrs color "#111111")
                (text-escape text)))))

(define (space-icon-svg x y width height color)
  (define icon-width (min (* width 0.2) 28))
  (define icon-height (min (* height 0.28) 12))
  (define left (+ x (/ (- width icon-width) 2)))
  (define right (+ left icon-width))
  (define top (+ y (/ (- height icon-height) 2)))
  (define bottom (+ top icon-height))
  (format "<path d=\"M ~a ~a V ~a H ~a V ~a\" fill=\"none\" stroke=\"~a\" stroke-width=\"1.7\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"
          (real->decimal-string left 2)
          (real->decimal-string top 2)
          (real->decimal-string bottom 2)
          (real->decimal-string right 2)
          (real->decimal-string top 2)
          (attr-escape color)))

(define (stroke-icon-path d color)
  (format "<path d=\"~a\" fill=\"none\" stroke=\"~a\" stroke-width=\"1.9\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"
          d
          (attr-escape color)))

(define (special-icon-svg kind x y width height color)
  (define cx (+ x (/ width 2)))
  (define cy (+ y (/ height 2)))
  (match kind
    [(or "space" "space.fill") (space-icon-svg x y width height color)]
    [(or "shift" "shift.fill" "capslock.fill")
     (stroke-icon-path
      (format "M ~a ~a L ~a ~a L ~a ~a M ~a ~a V ~a"
              (real->decimal-string (- cx 10) 2)
              (real->decimal-string (+ cy 1) 2)
              (real->decimal-string cx 2)
              (real->decimal-string (- cy 10) 2)
              (real->decimal-string (+ cx 10) 2)
              (real->decimal-string (+ cy 1) 2)
              (real->decimal-string cx 2)
              (real->decimal-string (- cy 10) 2)
              (real->decimal-string (+ cy 12) 2))
      color)]
    [(or "backspace" "delete.left" "delete.left.fill")
     (stroke-icon-path
      (format "M ~a ~a L ~a ~a H ~a V ~a H ~a L ~a ~a M ~a ~a L ~a ~a M ~a ~a L ~a ~a"
              (real->decimal-string (- cx 14) 2)
              (real->decimal-string cy 2)
              (real->decimal-string (- cx 5) 2)
              (real->decimal-string (- cy 9) 2)
              (real->decimal-string (+ cx 14) 2)
              (real->decimal-string (+ cy 9) 2)
              (real->decimal-string (- cx 5) 2)
              (real->decimal-string (- cx 14) 2)
              (real->decimal-string cy 2)
              (real->decimal-string (- cx 2) 2)
              (real->decimal-string (- cy 4) 2)
              (real->decimal-string (+ cx 6) 2)
              (real->decimal-string (+ cy 4) 2)
              (real->decimal-string (+ cx 6) 2)
              (real->decimal-string (- cy 4) 2)
              (real->decimal-string (- cx 2) 2)
              (real->decimal-string (+ cy 4) 2))
      color)]
    ["enter"
     (stroke-icon-path
      (format "M ~a ~a V ~a H ~a M ~a ~a L ~a ~a L ~a ~a"
              (real->decimal-string (+ cx 11) 2)
              (real->decimal-string (- cy 10) 2)
              (real->decimal-string (+ cy 6) 2)
              (real->decimal-string (- cx 9) 2)
              (real->decimal-string (- cx 4) 2)
              (real->decimal-string (+ cy 1) 2)
              (real->decimal-string (- cx 9) 2)
              (real->decimal-string (+ cy 6) 2)
              (real->decimal-string (- cx 4) 2)
              (real->decimal-string (+ cy 11) 2))
      color)]
    [(or "face.smiling" "emojis")
     (string-append
      (format "<circle cx=\"~a\" cy=\"~a\" r=\"~a\" fill=\"none\" stroke=\"~a\" stroke-width=\"1.9\"/>"
              (real->decimal-string cx 2)
              (real->decimal-string cy 2)
              (real->decimal-string (min 12 (* width 0.2)) 2)
              (attr-escape color))
      (format "<circle cx=\"~a\" cy=\"~a\" r=\"1.35\" fill=\"~a\"/>"
              (real->decimal-string (- cx 4.2) 2)
              (real->decimal-string (- cy 3.2) 2)
              (attr-escape color))
      (format "<circle cx=\"~a\" cy=\"~a\" r=\"1.35\" fill=\"~a\"/>"
              (real->decimal-string (+ cx 4.2) 2)
              (real->decimal-string (- cy 3.2) 2)
              (attr-escape color))
      (format "<path d=\"M ~a ~a Q ~a ~a ~a ~a\" fill=\"none\" stroke=\"~a\" stroke-width=\"1.8\" stroke-linecap=\"round\"/>"
              (real->decimal-string (- cx 5.5) 2)
              (real->decimal-string (+ cy 3.2) 2)
              (real->decimal-string cx 2)
              (real->decimal-string (+ cy 7.2) 2)
              (real->decimal-string (+ cx 5.5) 2)
              (real->decimal-string (+ cy 3.2) 2)
              (attr-escape color)))]
    [_ #f]))

(define (fallback-label-svg key x y width height)
  (define color (fallback-color (hash-get key 'background "#ffffff")))
  (define kind (hash-get key 'kind ""))
  (define icon (or (special-icon-svg kind x y width height color)
                   (special-icon-svg (hash-get key 'icon "") x y width height color)))
  (if icon
      icon
      (let ([label (special-label key)])
        (if (or (not (string? label)) (string=? label ""))
            ""
            (format "<text x=\"~a\" y=\"~a\" text-anchor=\"middle\" dominant-baseline=\"central\" font-family=\"Avenir Next, SF Pro Display, Segoe UI, Noto Sans, PingFang TC, sans-serif\" font-size=\"~a\" font-weight=\"500\" fill=\"~a\">~a</text>"
                    (real->decimal-string (+ x (/ width 2)) 2)
                    (real->decimal-string (+ y (/ height 2)) 2)
                    (real->decimal-string (if (equal? (hash-get key 'kind "") "numeric") 16 18) 2)
                    (attr-escape color)
                    (text-escape label))))))

(define (key-svg key x y width height)
  (define background (hash-get key 'background "#ffffff"))
  (define layers (hash-get key 'layers '()))
  (string-append
   (format "<rect x=\"~a\" y=\"~a\" width=\"~a\" height=\"~a\" rx=\"8\" ~a ~a/>"
           (real->decimal-string x 2)
           (real->decimal-string y 2)
           (real->decimal-string width 2)
           (real->decimal-string height 2)
           (fill-attrs background "#ffffff")
           (stroke-attrs (key-stroke-color background) 0.75))
   (if (and (list? layers) (pair? layers))
       (apply string-append
              (for/list ([layer (in-list layers)])
                (text-layer-svg layer x y width height 1.02)))
       (fallback-label-svg key x y width height))))

(define (keyboard-body-svg preview)
  (define size (hash-get preview 'size (hash)))
  (define width (numberish (hash-get size 'width 375) 375))
  (define height (numberish (hash-get size 'height 216) 216))
  (define rows (hash-get preview 'rows '()))
  (define row-count (max 1 (length rows)))
  (define key-height (/ (- height (* (+ row-count 1) row-gap)) row-count))
  (apply
   string-append
   (for/list ([row (in-list rows)]
              [row-index (in-naturals)])
     (define y (+ row-gap (* row-index (+ key-height row-gap))))
     (define total-units
       (let ([sum (apply + (map (lambda (key) (numberish (hash-get key 'width 1) 1)) row))])
         (if (positive? sum) sum 1)))
     (define available-width (- width (* 2 keyboard-pad) (* (max 0 (sub1 (length row))) key-gap)))
     (let loop ([keys row] [x keyboard-pad] [pieces '()])
       (match keys
         ['() (apply string-append (reverse pieces))]
         [(cons key rest)
          (define key-width (* (/ (numberish (hash-get key 'width 1) 1) total-units)
                               available-width))
          (loop rest
                (+ x key-width key-gap)
                (cons (key-svg key x y key-width key-height) pieces))])))))

(define (keyboard-preview-svg preview)
  (define size (hash-get preview 'size (hash)))
  (define width (numberish (hash-get size 'width 375) 375))
  (define height (numberish (hash-get size 'height 216) 216))
  (define background (hash-get preview 'background "#f2f3f7"))
  (format "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 ~a ~a\" role=\"img\" aria-label=\"Keyboard preview\"><rect width=\"~a\" height=\"~a\" rx=\"18\" ~a/>~a</svg>"
          (real->decimal-string width 2)
          (real->decimal-string height 2)
          (real->decimal-string width 2)
          (real->decimal-string height 2)
          (fill-attrs background "#f2f3f7")
          (keyboard-body-svg preview)))

(define (demo-preview-svg title preview)
  (define keyboard-x 68)
  (define keyboard-y 120)
  (define keyboard-width 860)
  (define keyboard-height 482)
  (define size (hash-get preview 'size (hash)))
  (define logical-width (numberish (hash-get size 'width 375) 375))
  (define logical-height (numberish (hash-get size 'height 216) 216))
  (define scale (min (/ keyboard-width logical-width)
                     (/ keyboard-height logical-height)))
  (define scaled-width (* logical-width scale))
  (define scaled-height (* logical-height scale))
  (define offset-x (+ keyboard-x (/ (- keyboard-width scaled-width) 2)))
  (define offset-y (+ keyboard-y (/ (- keyboard-height scaled-height) 2)))
  (format "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"~a\" height=\"~a\" viewBox=\"0 0 ~a ~a\" role=\"img\" aria-label=\"~a\"><rect width=\"100%\" height=\"100%\" fill=\"#F6F7FA\"/><rect x=\"42\" y=\"36\" width=\"912\" height=\"588\" rx=\"42\" fill=\"#ECEEF4\" stroke=\"#D7D9E1\"/><text x=\"498\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"central\" font-family=\"Avenir Next, SF Pro Display, Segoe UI, Noto Sans, PingFang TC, sans-serif\" font-size=\"38\" font-weight=\"700\" fill=\"#202124\">~a</text><g transform=\"translate(~a ~a) scale(~a)\">~a</g></svg>"
          demo-width
          demo-height
          demo-width
          demo-height
          (attr-escape title)
          (text-escape title)
          (real->decimal-string offset-x 2)
          (real->decimal-string offset-y 2)
          (real->decimal-string scale 4)
          (keyboard-preview-svg preview)))

(define (preview-spec->svgs preview-spec)
  (cond
    [(not (hash? preview-spec)) (hash)]
    [else
     (define light-preview (hash-remove preview-spec 'dark))
     (define dark-preview (hash-ref preview-spec 'dark #f))
     (define light-svgs (hash 'light (keyboard-preview-svg light-preview)))
     (if (hash? dark-preview)
         (hash-set light-svgs 'dark (keyboard-preview-svg dark-preview))
         light-svgs)]))
