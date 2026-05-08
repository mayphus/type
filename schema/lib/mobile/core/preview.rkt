#lang racket/base

(require racket/hash
         racket/list
         racket/string
         json)

(provide preview-spec-from-files
         preview-layout
         preview-key-visible?)

(define preview-logical-width 375)
(define preview-min-key-columns 10)
;; Use the search return-key state so previews match common iOS search fields.
(define preview-return-key-type 6)
(define return-key-labels
  (hash 6 "搜尋"))

(define (page-ref page key [default #f])
  (cond
    [(symbol? key) (hash-ref page key default)]
    [(string? key) (hash-ref page (string->symbol key) default)]
    [else default]))

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

(define (preview-size page)
  (define keyboard-height
    (parse-numberish (page-ref page 'keyboardHeight #f)))
  (and keyboard-height
       (positive? keyboard-height)
       (hash 'width preview-logical-width
             'height keyboard-height)))

(define (style-color style)
  (or (page-ref style 'normalColor #f)
      (page-ref style 'highlightColor #f)))

(define (return-key-label)
  (hash-ref return-key-labels preview-return-key-type "$returnKeyType"))

(define (preview-text text)
  (if (equal? text "$returnKeyType")
      (return-key-label)
      text))

(define (style-name? value)
  (or (string? value) (symbol? value)))

(define (style-name->string value)
  (cond
    [(string? value) value]
    [(symbol? value) (symbol->string value)]
    [else #f]))

(define (number-matches? value expected)
  (define n (parse-numberish value))
  (and n (= n expected)))

(define (condition-values-match? value expected)
  (cond
    [(vector? value)
     (for/or ([item (in-vector value)])
       (number-matches? item expected))]
    [(list? value)
     (for/or ([item (in-list value)])
       (number-matches? item expected))]
    [else (number-matches? value expected)]))

(define (condition-style-name condition)
  (and (hash? condition)
       (style-name->string (page-ref condition 'styleName #f))))

(define (return-key-condition? condition)
  (and (hash? condition)
       (equal? (page-ref condition 'conditionKey #f) "$returnKeyType")
       (condition-values-match?
        (page-ref condition 'conditionValue '())
        preview-return-key-type)))

(define (conditional-style-ref items)
  (or (for/or ([item (in-list items)]
               #:when (return-key-condition? item))
        (condition-style-name item))
      (for/or ([item (in-list items)]
               #:when (condition-style-name item))
        (condition-style-name item))))

(define (text-style-layer page style-name)
  (define style (page-ref page style-name #f))
  (and (hash? style)
       (equal? (page-ref style 'buttonStyleType #f) "text")
       (let ([center (page-ref style 'center (hash))]
             [text (preview-text (page-ref style 'text ""))])
         (hash 'text text
               'x (or (page-ref center 'x #f) 0.5)
               'y (or (page-ref center 'y #f) 0.5)
               'font-size (or (page-ref style 'fontSize #f) 14)
               'font-weight (or (page-ref style 'fontWeight #f) "")
               'color (or (style-color style) "#000000")))))

(define (normalize-style-refs value)
  (cond
    [(style-name? value) (list (style-name->string value))]
    [(vector? value)
     (define items (vector->list value))
     (if (ormap hash? items)
         (let ([ref (conditional-style-ref items)])
           (if ref (list ref) '()))
         (filter values (map style-name->string items)))]
    [(list? value)
     (if (ormap hash? value)
         (let ([ref (conditional-style-ref value)])
           (if ref (list ref) '()))
         (filter values (map style-name->string value)))]
    [else '()]))

(define (style-ref value)
  (cond
    [(style-name? value) (style-name->string value)]
    [(hash? value) (condition-style-name value)]
    [(vector? value)
     (let ([items (vector->list value)])
       (or (conditional-style-ref items)
           (for/or ([item (in-list items)]
                    #:when (style-name? item))
             (style-name->string item))))]
    [(list? value)
     (or (conditional-style-ref value)
         (for/or ([item (in-list value)]
                  #:when (style-name? item))
           (style-name->string item)))]
    [else #f]))

(define (button-kind button-id button)
  (define action (page-ref button 'action #f))
  (cond
    [(string? action) action]
    [(string-contains? button-id "space") "space"]
    [(string-contains? button-id "backspace") "backspace"]
    [(string-contains? button-id "shift") "shift"]
    [(string-contains? button-id "enter") "enter"]
    [(string-contains? button-id "numeric") "numeric"]
    [else "key"]))

(define (button-icon page style-name)
  (define style (page-ref page style-name #f))
  (and (hash? style)
       (equal? (page-ref style 'buttonStyleType #f) "systemImage")
       (or (page-ref style 'systemImageName #f)
           (page-ref style 'highlightSystemImageName #f))))

(define (button-icon-size page style-name)
  (define style (page-ref page style-name #f))
  (and (hash? style)
       (equal? (page-ref style 'buttonStyleType #f) "systemImage")
       (parse-numberish (page-ref style 'fontSize #f))))

(define (preview-insets value)
  (and (hash? value)
       (hash 'top (or (parse-numberish (page-ref value 'top #f)) 0)
             'right (or (parse-numberish (page-ref value 'right #f)) 0)
             'bottom (or (parse-numberish (page-ref value 'bottom #f)) 0)
             'left (or (parse-numberish (page-ref value 'left #f)) 0))))

(define (layout-spacer-cell? cell-id)
  (and (string? cell-id)
       (regexp-match? #rx"Spacer$" cell-id)))

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

(define (extract-key-preview page button-id)
  (define button (page-ref page button-id #f))
  (and (hash? button)
       (let* ([foreground-refs (normalize-style-refs (page-ref button 'foregroundStyle '()))]
              [layers (filter values (map (lambda (ref) (text-style-layer page ref)) foreground-refs))]
              [sorted-layers
               (sort layers
                     (lambda (left right)
                       (> (hash-ref left 'font-size 0)
                          (hash-ref right 'font-size 0))))]
              [primary-layer
               (or (findf (lambda (layer)
                            (and (string? (hash-ref layer 'text ""))
                                 (not (string=? (hash-ref layer 'text "") ""))))
                          sorted-layers)
                   (and (pair? sorted-layers) (car sorted-layers)))]
              [background-style-name (style-ref (page-ref button 'backgroundStyle #f))]
              [background-style (and background-style-name
                                     (page-ref page background-style-name #f))]
              [size (page-ref button 'size (hash))]
              [bounds (page-ref button 'bounds (hash))]
              [icon
               (let loop ([refs foreground-refs])
                 (cond
                   [(null? refs) #f]
                   [else (or (button-icon page (car refs))
                             (loop (cdr refs)))]))]
              [icon-size
               (let loop ([refs foreground-refs])
                 (cond
                   [(null? refs) #f]
                   [else (or (button-icon-size page (car refs))
                             (loop (cdr refs)))]))])
         (hash 'id button-id
               'kind (button-kind button-id button)
               'spacer? (layout-spacer-cell? button-id)
               'label (or (and primary-layer (hash-ref primary-layer 'text "")) "")
               'icon (or icon "")
               'icon-size (or icon-size 20)
               'width (or (parse-numberish (page-ref size 'width #f)) 1)
               'height (parse-numberish (page-ref size 'height #f))
               'align (or (page-ref bounds 'alignment #f) "center")
               'background (or (and (hash? background-style) (page-ref background-style 'normalColor #f))
                               "#ffffff")
               'highlight-background (or (and (hash? background-style) (page-ref background-style 'highlightColor #f))
                                         "#e6e6e6")
               'corner-radius (or (and (hash? background-style)
                                       (parse-numberish (page-ref background-style 'cornerRadius #f)))
                                  8)
               'insets (or (and (hash? background-style)
                                (preview-insets (page-ref background-style 'insets #f)))
                           (hash 'top 0 'right 0 'bottom 0 'left 0))
               'layers sorted-layers))))

(define (extract-row-preview page row-spec)
  (define hstack (page-ref row-spec 'HStack #f))
  (define subviews (and (hash? hstack) (page-ref hstack 'subviews '())))
  (filter values
          (for/list ([subview (in-list (if (vector? subviews) (vector->list subviews) subviews))]
                     #:when (hash? subview)
                     [cell-id (in-value (page-ref subview 'Cell ""))])
            (extract-key-preview page cell-id))))

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
  (define (row-units row)
    (apply + (map (lambda (key)
                    (or (parse-numberish (hash-ref key 'width #f)) 1))
                  row)))
  (for/list ([row (in-list rows)]
             [row-index (in-naturals)])
    (define y (+ row-gap (* row-index (+ key-height row-gap))))
    (define row-gap-count (max 0 (sub1 (length row))))
    (define units (max 1 (row-units row)))
    (define unit-width (/ (- width (* 2 pad) (* row-gap-count key-gap)) units))
    (let loop ([keys row] [x pad] [items '()])
      (cond
        [(null? keys) (reverse items)]
        [else
         (define key (car keys))
         (define width-units (or (parse-numberish (hash-ref key 'width #f)) 1))
         (define key-width (* width-units unit-width))
         (define explicit-height-units (parse-numberish (hash-ref key 'height #f)))
         (define item-height
           (if (and explicit-height-units (positive? explicit-height-units))
               (* key-width (/ explicit-height-units width-units))
               key-height))
         (define item-y (+ y (/ (- key-height item-height) 2)))
         (loop (cdr keys)
               (+ x key-width key-gap)
               (cons (hash 'key key
                           'x x
                           'y item-y
                           'width key-width
                           'height item-height)
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

(define (preferred-preview-page-path preview-files theme)
  (define keys (hash-keys preview-files))
  (define prefix (regexp-quote theme))
  (or (findf (lambda (key) (regexp-match? (regexp (format "^~a/pinyinPortrait\\.yaml$" prefix)) key)) keys)
      (findf (lambda (key) (regexp-match? (regexp (format "^~a/.*Portrait\\.yaml$" prefix)) key)) keys)
      (findf (lambda (key) (regexp-match? (regexp (format "^~a/.*\\.yaml$" prefix)) key)) keys)))

(define (preview-spec-from-page preview-files
                                theme
                                #:source source
                                #:key-shape key-shape
                                #:visible-keys visible-keys)
  (with-handlers ([exn:fail? (lambda (_) #f)])
    (define page-path (preferred-preview-page-path preview-files theme))
    (and page-path
         (let* ([page-json (hash-ref preview-files page-path #f)]
                [page (and page-json
                           (bytes->jsexpr (string->bytes/utf-8 page-json)))]
                [keyboard-layout (and (hash? page) (page-ref page 'keyboardLayout '()))]
                [keyboard-style (and (hash? page)
                                     (page-ref page (page-ref (page-ref page 'keyboardStyle (hash))
                                                              'backgroundStyle "")
                                               #f))]
                [size (and (hash? page) (preview-size page))]
                [rows
                 (and (list? keyboard-layout)
                      (filter values
                              (map (lambda (row)
                                     (let ([preview-row (extract-row-preview page row)])
                                       (and (pair? preview-row) preview-row)))
                                   keyboard-layout)))])
           (and (pair? rows)
                (hash 'page page-path
                      'source source
                      'key-shape key-shape
                      'visible-keys visible-keys
                      'background (or (and (hash? keyboard-style)
                                           (page-ref keyboard-style 'normalColor #f))
                                      "#ffffff03")
                      'size size
                      'rows rows))))))

(define (preview-spec-from-files preview-files
                                 #:source [source 'dsl]
                                 #:key-shape [key-shape 'square]
                                 #:visible-keys [visible-keys 'typing])
  (define (extract theme)
    (preview-spec-from-page preview-files
                            theme
                            #:source source
                            #:key-shape key-shape
                            #:visible-keys visible-keys))
  (define light-preview (extract "light"))
  (define dark-preview (extract "dark"))
  (cond
    [(and light-preview dark-preview)
     (hash-set light-preview 'dark dark-preview)]
    [light-preview light-preview]
    [dark-preview dark-preview]
    [else #f]))

(module+ test
  (require rackunit)

  (define conditional-page
    (jsexpr->string
     (hash 'keyboardHeight 216
           'keyboardStyle (hash 'backgroundStyle "keyboardBackgroundStyle")
           'keyboardBackgroundStyle (hash 'buttonStyleType "geometry"
                                          'normalColor "#00000003")
           'systemButtonBackgroundStyle (hash 'buttonStyleType "geometry"
                                              'cornerRadius 8.5
                                              'insets (hash 'top 4 'right 3 'bottom 4 'left 3)
                                              'normalColor "#4C4C4C"
                                              'highlightColor "#707070")
           'blueButtonBackgroundStyle (hash 'buttonStyleType "geometry"
                                            'normalColor "#0A84FF"
                                            'highlightColor "#707070")
           'enterButtonForegroundStyle (hash 'buttonStyleType "text"
                                             'fontSize 16
                                             'normalColor "#FFFFFF"
                                             'text "$returnKeyType")
           'blueButtonForegroundStyle (hash 'buttonStyleType "text"
                                            'fontSize 16
                                            'normalColor "#FFFFFF"
                                            'text "$returnKeyType")
           'enterButton (hash 'action "enter"
                              'backgroundStyle
                              (list (hash 'conditionKey "$returnKeyType"
                                          'conditionValue (list 0 2 3 5 6 8 11)
                                          'styleName "systemButtonBackgroundStyle")
                                    (hash 'conditionKey "$returnKeyType"
                                          'conditionValue (list 1 4 7 9 10)
                                          'styleName "blueButtonBackgroundStyle"))
                              'foregroundStyle
                              (list (hash 'conditionKey "$returnKeyType"
                                          'conditionValue (list 0 2 3 5 6 8 11)
                                          'styleName "enterButtonForegroundStyle")
                                    (hash 'conditionKey "$returnKeyType"
                                          'conditionValue (list 1 4 7 9 10)
                                          'styleName "blueButtonForegroundStyle"))
                              'size (hash 'width "280/1125"))
           'keyboardLayout
           (list (hash 'HStack (hash 'subviews
                                     (list (hash 'Cell "enterButton"))))))))

  (define preview
    (preview-spec-from-files
     (hash "light/pinyinPortrait.yaml" conditional-page
           "dark/pinyinPortrait.yaml" conditional-page)))
  (define enter-key
    (first (first (hash-ref (hash-ref preview 'dark) 'rows))))

  (check-equal? (hash-ref enter-key 'background) "#4C4C4C")
  (check-equal? (hash-ref enter-key 'label) "搜尋")
  (check-equal? (hash-ref enter-key 'corner-radius) 8.5)
  (check-equal? (hash-ref (hash-ref enter-key 'insets) 'top) 4)
  (check-equal? (hash-ref (hash-ref enter-key 'insets) 'left) 3)
  (check-equal? (hash-ref (first (hash-ref enter-key 'layers)) 'text) "搜尋"))
