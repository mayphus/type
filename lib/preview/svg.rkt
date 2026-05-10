#lang racket/base

(require racket/format
         racket/match
         racket/string
         "spec.rkt")

(provide keyboard-preview-svg
         keyboard-skin-preview-svg
         demo-preview-svg
         preview-spec->svgs)

(define demo-width 996)
(define demo-height 770)
(define demo-keyboard-scale 1.0)
(define keyboard-pad 8)
(define key-gap 4)
(define row-gap 6)
(define default-key-corner-radius 6)

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

(define (key-corner-radius _key)
  default-key-corner-radius)

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

(define (fitted-font-size text width height requested-size)
  (define text-length (max 1 (string-length text)))
  (define width-fit (/ (* width 0.86) (* text-length 0.56)))
  (define height-fit (* height 0.4))
  (max 5.5 (min requested-size width-fit height-fit)))

(define (text-layer-svg layer x y width height scale)
  (text-layer-svg* layer x y width height scale (hash-get layer 'color "#111111")))

(define (text-layer-svg* layer x y width height scale color)
  (define text (hash-get layer 'text ""))
  (if (or (not (string? text)) (string=? text ""))
      ""
      (let* ([lx (+ x (* (numberish (hash-get layer 'x 0.5) 0.5) width))]
             [ly (+ y (* (numberish (hash-get layer 'y 0.5) 0.5) height))]
             [requested-size (* scale (numberish (hash-get layer 'font-size 14) 14))]
             [font-size (fitted-font-size text width height requested-size)])
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

(define (special-icon-svg kind x y width height color [icon-size 20])
  (define cx (+ x (/ width 2)))
  (define cy (+ y (/ height 2)))
  (define face-scale (/ (min (* icon-size 0.5) (* width 0.32) (* height 0.34)) 12))
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
     (define r (* 12 face-scale))
     (string-append
      (format "<circle cx=\"~a\" cy=\"~a\" r=\"~a\" fill=\"none\" stroke=\"~a\" stroke-width=\"1.9\"/>"
              (real->decimal-string cx 2)
              (real->decimal-string cy 2)
              (real->decimal-string r 2)
              (attr-escape color))
      (format "<circle cx=\"~a\" cy=\"~a\" r=\"~a\" fill=\"~a\"/>"
              (real->decimal-string (- cx (* 4.2 face-scale)) 2)
              (real->decimal-string (- cy (* 3.2 face-scale)) 2)
              (real->decimal-string (* 1.35 face-scale) 2)
              (attr-escape color))
      (format "<circle cx=\"~a\" cy=\"~a\" r=\"~a\" fill=\"~a\"/>"
              (real->decimal-string (+ cx (* 4.2 face-scale)) 2)
              (real->decimal-string (- cy (* 3.2 face-scale)) 2)
              (real->decimal-string (* 1.35 face-scale) 2)
              (attr-escape color))
      (format "<path d=\"M ~a ~a Q ~a ~a ~a ~a\" fill=\"none\" stroke=\"~a\" stroke-width=\"~a\" stroke-linecap=\"round\"/>"
              (real->decimal-string (- cx (* 5.5 face-scale)) 2)
              (real->decimal-string (+ cy (* 3.2 face-scale)) 2)
              (real->decimal-string cx 2)
              (real->decimal-string (+ cy (* 7.2 face-scale)) 2)
              (real->decimal-string (+ cx (* 5.5 face-scale)) 2)
              (real->decimal-string (+ cy (* 3.2 face-scale)) 2)
              (attr-escape color)
              (real->decimal-string (* 1.8 face-scale) 2)))]
    [_ #f]))

(define (fallback-label-svg key x y width height)
  (define color (fallback-color (hash-get key 'background "#ffffff")))
  (define kind (hash-get key 'kind ""))
  (define icon-size (numberish (hash-get key 'icon-size 20) 20))
  (define icon (or (special-icon-svg kind x y width height color icon-size)
                   (special-icon-svg (hash-get key 'icon "") x y width height color icon-size)))
  (if icon
      icon
      (let ([label (special-label key)])
        (if (or (not (string? label)) (string=? label ""))
            ""
            (format "<text x=\"~a\" y=\"~a\" text-anchor=\"middle\" dominant-baseline=\"central\" font-family=\"Avenir Next, SF Pro Display, Segoe UI, Noto Sans, PingFang TC, sans-serif\" font-size=\"~a\" font-weight=\"400\" fill=\"~a\">~a</text>"
                    (real->decimal-string (+ x (/ width 2)) 2)
                    (real->decimal-string (+ y (/ height 2)) 2)
                    (real->decimal-string
                     (fitted-font-size label width height
                                       (if (equal? (hash-get key 'kind "") "numeric") 16 18))
                     2)
                    (attr-escape color)
                    (text-escape label))))))

(define (key-svg key x y width height)
  (define background (hash-get key 'background "#ffffff"))
  (define layers (hash-get key 'layers '()))
  (define radius (key-corner-radius key))
  (string-append
   (format "<rect x=\"~a\" y=\"~a\" width=\"~a\" height=\"~a\" rx=\"~a\" ~a ~a/>"
           (real->decimal-string x 2)
           (real->decimal-string y 2)
           (real->decimal-string width 2)
           (real->decimal-string height 2)
           (real->decimal-string radius 2)
           (fill-attrs background "#ffffff")
           (stroke-attrs (key-stroke-color background) 0.75))
   (if (and (list? layers) (pair? layers))
       (apply string-append
              (for/list ([layer (in-list layers)])
                (text-layer-svg layer x y width height 1.02)))
       (fallback-label-svg key x y width height))))

(define (diagram-colors preview)
  (if (color-bright? (hash-get preview 'background "#f2f3f7"))
      (hash 'background "#f6f7f9"
            'key "#ffffff"
            'special "#e9edf2"
            'stroke "#6c748014"
            'text "#1d232b"
            'muted-text "#596270")
      (hash 'background "#111418"
            'key "#222830"
            'special "#303844"
            'stroke "#ffffff1c"
            'text "#f4f6f8"
            'muted-text "#c8d0da")))

(define (special-key? key)
  (or (member (hash-get key 'kind "")
              '("shift" "backspace" "enter" "space" "numeric" "emojis" "face.smiling"))
      (member (hash-get key 'icon "")
              '("shift" "shift.fill" "capslock.fill" "delete.left" "delete.left.fill"
                "space" "space.fill" "face.smiling"))))

(define (diagram-label-svg key x y width height colors)
  (define color (hash-ref colors (if (special-key? key) 'muted-text 'text)))
  (define layers (hash-get key 'layers '()))
  (if (and (list? layers) (pair? layers))
      (apply string-append
             (for/list ([layer (in-list layers)])
               (text-layer-svg* layer x y width height 1.0 color)))
      (let* ([kind (hash-get key 'kind "")]
             [icon-size (numberish (hash-get key 'icon-size 20) 20)]
             [icon (or (special-icon-svg kind x y width height color icon-size)
                       (special-icon-svg (hash-get key 'icon "") x y width height color icon-size))]
             [label (special-label key)])
        (cond
          [icon icon]
          [(or (not (string? label)) (string=? label "")) ""]
          [else
           (format "<text x=\"~a\" y=\"~a\" text-anchor=\"middle\" dominant-baseline=\"central\" font-family=\"Avenir Next, SF Pro Display, Segoe UI, Noto Sans, PingFang TC, sans-serif\" font-size=\"~a\" font-weight=\"400\" fill=\"~a\">~a</text>"
                   (real->decimal-string (+ x (/ width 2)) 2)
                   (real->decimal-string (+ y (/ height 2)) 2)
                   (real->decimal-string
                    (fitted-font-size label width height (if (equal? kind "numeric") 15 17))
                    2)
                   (attr-escape color)
                   (text-escape label))]))))

(define (diagram-key-svg key x y width height colors)
  (define fill (hash-ref colors (if (special-key? key) 'special 'key)))
  (string-append
   (format "<rect x=\"~a\" y=\"~a\" width=\"~a\" height=\"~a\" rx=\"~a\" fill=\"~a\" stroke=\"~a\" stroke-width=\"1\"/>"
           (real->decimal-string x 2)
           (real->decimal-string y 2)
           (real->decimal-string width 2)
           (real->decimal-string height 2)
           (real->decimal-string default-key-corner-radius 2)
           (attr-escape fill)
           (attr-escape (hash-ref colors 'stroke)))
   (diagram-label-svg key x y width height colors)))

(define (keyboard-layout-items preview geometry)
  (preview-layout preview
                  #:pad keyboard-pad
                  #:key-gap key-gap
                  #:row-gap row-gap
                  #:geometry geometry))

(define (layout-y-bounds layout)
  (for*/fold ([min-y +inf.0]
              [max-y 0])
             ([row (in-list layout)]
              [item (in-list row)])
    (define y (hash-get item 'y 0))
    (define height (hash-get item 'height 0))
    (values (min min-y y)
            (max max-y (+ y height)))))

(define (compact-layout-metrics preview geometry)
  (define size (hash-get preview 'size (hash)))
  (define width (numberish (hash-get size 'width 375) 375))
  (define source-height (numberish (hash-get size 'height 216) 216))
  (define layout (keyboard-layout-items preview geometry))
  (cond
    [(null? layout)
     (values width source-height 0 layout)]
    [else
     (define-values (min-y max-y) (layout-y-bounds layout))
     (define compact-height (+ (* 2 keyboard-pad) (- max-y min-y)))
     (values width compact-height (- keyboard-pad min-y) layout)]))

(define (keyboard-body-svg layout y-offset)
  (apply
   string-append
   (for*/list ([row (in-list layout)]
               [item (in-list row)]
               #:unless (hash-get (hash-get item 'key (hash)) 'spacer? #f))
     (key-svg (hash-get item 'key (hash))
              (hash-get item 'x 0)
              (+ (hash-get item 'y 0) y-offset)
              (hash-get item 'width 0)
              (hash-get item 'height 0)))))

(define (keyboard-diagram-body-svg layout colors y-offset)
  (apply
   string-append
   (for*/list ([row (in-list layout)]
               [item (in-list row)]
               #:unless (hash-get (hash-get item 'key (hash)) 'spacer? #f))
     (diagram-key-svg (hash-get item 'key (hash))
                      (hash-get item 'x 0)
                      (+ (hash-get item 'y 0) y-offset)
                      (hash-get item 'width 0)
                      (hash-get item 'height 0)
                      colors))))

(define (keyboard-preview-svg preview #:geometry [geometry 'uniform-square])
  (define-values (width height y-offset layout)
    (compact-layout-metrics preview geometry))
  (define colors (diagram-colors preview))
  (format "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"~a\" height=\"~a\" viewBox=\"0 0 ~a ~a\" role=\"img\" aria-label=\"Keyboard preview\"><rect width=\"~a\" height=\"~a\" rx=\"12\" fill=\"~a\"/>~a</svg>"
          (real->decimal-string width 2)
          (real->decimal-string height 2)
          (real->decimal-string width 2)
          (real->decimal-string height 2)
          (real->decimal-string width 2)
          (real->decimal-string height 2)
          (attr-escape (hash-ref colors 'background))
          (keyboard-diagram-body-svg layout colors y-offset)))

(define (skin-preview-spec preview)
  (hash-set preview 'visible-keys 'all))

(define (keyboard-skin-preview-svg preview)
  (keyboard-preview-svg (skin-preview-spec preview)
                        #:geometry 'skin-proportional))

(define (demo-preview-svg title preview)
  (define panel-x 92)
  (define panel-y 150)
  (define panel-width 812)
  (define panel-height 548)
  (define keyboard-x (+ panel-x 34))
  (define keyboard-y (+ panel-y 84))
  (define keyboard-width (- panel-width 68))
  (define keyboard-height (- panel-height 116))
  (define demo-preview (skin-preview-spec preview))
  (define size (hash-get demo-preview 'size (hash)))
  (define logical-width (numberish (hash-get size 'width 375) 375))
  (define-values (_compact-width logical-height _y-offset _layout)
    (compact-layout-metrics demo-preview 'skin-proportional))
  (define scale (* demo-keyboard-scale
                   (min (/ keyboard-width logical-width)
                        (/ keyboard-height logical-height))))
  (define scaled-width (* logical-width scale))
  (define scaled-height (* logical-height scale))
  (define offset-x (+ keyboard-x (/ (- keyboard-width scaled-width) 2)))
  (define offset-y (+ keyboard-y (/ (- keyboard-height scaled-height) 2)))
  (format "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"~a\" height=\"~a\" viewBox=\"0 0 ~a ~a\" role=\"img\" aria-label=\"~a\"><rect width=\"100%\" height=\"100%\" fill=\"#FAFAFA\"/><text x=\"~a\" y=\"72\" font-family=\"Avenir Next, SF Pro Display, Segoe UI, Noto Sans, PingFang TC, sans-serif\" font-size=\"42\" font-weight=\"700\" fill=\"#5F6368\">~a</text><text x=\"~a\" y=\"116\" font-family=\"Avenir Next, SF Pro Display, Segoe UI, Noto Sans, PingFang TC, sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"#6F747B\">作者： Mayphus</text><rect x=\"~a\" y=\"~a\" width=\"~a\" height=\"~a\" rx=\"30\" fill=\"#E9ECEF\"/><g transform=\"translate(~a ~a) scale(~a)\">~a</g></svg>"
          demo-width
          demo-height
          demo-width
          demo-height
          (attr-escape title)
          panel-x
          (text-escape title)
          panel-x
          panel-x
          panel-y
          panel-width
          panel-height
          (real->decimal-string offset-x 2)
          (real->decimal-string offset-y 2)
          (real->decimal-string scale 4)
          (keyboard-skin-preview-svg preview)))

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
