#lang racket/base

(require racket/hash
         racket/list
         racket/string
         "../core/dsl.rkt"
         "../layouts/base-page.rkt"
         "actions.rkt"
         "pinyin.rkt")

(provide make-letter-entry-hash)

(define (button-name letter)
  (string-append letter "Button"))

(define (letter-upper letter)
  (string-upcase letter))

(define standard-uppercase-font-size
  (json-number "22.5"))

(define hint-font-size 26)

(define (text-style dark? #:text text #:font-size font-size
                    #:center [center #f]
                    #:font-weight [font-weight #f]
                    #:secondary? [secondary? #f]
                    #:highlight? [highlight? #t])
  (append
   (list (cons "buttonStyleType" "text"))
   (if center (list (cons "center" center)) '())
   (list (cons "fontSize" font-size))
   (if font-weight (list (cons "fontWeight" font-weight)) '())
   (if highlight?
       (list (cons "highlightColor" (if secondary? (theme-secondary dark?) (theme-primary dark?))))
       '())
   (list (cons "normalColor" (if secondary? (theme-secondary dark?) (theme-primary dark?)))
         (cons "text" text))))

(define (split-flypy text)
  (define pieces (string-split text "\n"))
  (if (= (length pieces) 1)
      (values #f text)
      (values (first pieces) (second pieces))))

(define (style-name prefix layer)
  (case layer
    [(abc) (string-append prefix "AbcForegroundStyle")]
    [(abc-uppercase) (string-append prefix "AbcUppercaseForegroundStyle")]
    [(cangjie) (string-append prefix "CangjieForegroundStyle")]
    [(flypy-top) (string-append prefix "FlypyTopForegroundStyle")]
    [(flypy-bottom) (string-append prefix "FlypyBottomForegroundStyle")]
    [(symbol) (string-append prefix "SymbolForegroundStyle")]
    [else
     (string-append prefix
                    (regexp-replace* #rx"[^A-Za-z0-9]"
                                     (symbol->string layer)
                                     "")
                    "ForegroundStyle")]))

(define (layers->style-array prefix layers)
  (list->vector
   (for/list ([layer (in-list layers)])
     (style-name prefix layer))))

(define (config-ref config key [default #f])
  (hash-ref config key (lambda () default)))

(define (center-ref config key)
  (hash-ref (config-ref config 'centers default-legend-centers) key))

(define (enabled-layers config)
  (config-ref config 'enabled-layers '(abc cangjie flypy symbol)))

(define (layer-font-weight config key [default #f])
  (config-ref config key default))

(define (layer-config-key layer suffix)
  (string->symbol (format "~a-~a" layer suffix)))

(define (layer-font-size config layer [default 14])
  (config-ref config (layer-config-key layer "font-size") default))

(define (layer-secondary? config layer [default #f])
  (config-ref config (layer-config-key layer "secondary?") default))

(define (layer-weight config layer [default #f])
  (config-ref config (layer-config-key layer "font-weight") default))

(define (plain-text-layer? layer)
  (not (member layer '(abc cangjie flypy symbol))))

(define (plain-text-layer-entry dark? spec config layer)
  (define text (key-spec-layer-text spec layer))
  (cons (style-name (button-name (key-spec-letter spec)) layer)
        (text-style dark?
                    #:text text
                    #:center (center-ref config layer)
                    #:font-size (layer-font-size config layer)
                    #:font-weight (layer-weight config layer)
                    #:secondary? (layer-secondary? config layer))))

(define (make-letter-entry-hash dark? specs config)
  (define size-for (hash-ref config 'size-for))
  (define abc-font-size (hash-ref config 'abc-font-size))
  (define cangjie-font-size (hash-ref config 'cangjie-font-size))
  (define symbol-font-size (hash-ref config 'symbol-font-size))
  (define flypy-single-font-size (hash-ref config 'flypy-single-font-size))
  (define flypy-double-font-size (hash-ref config 'flypy-double-font-size))
  (define hint-style-extra (hash-ref config 'hint-style-extra))
  (define layers (enabled-layers config))
  (define abc-secondary? (config-ref config 'abc-secondary? #f))
  (define cangjie-secondary? (config-ref config 'cangjie-secondary? #f))
  (define flypy-secondary? (config-ref config 'flypy-secondary? #f))
  (define symbol-secondary? (config-ref config 'symbol-secondary? #t))
  (define cangjie-font-weight (layer-font-weight config 'cangjie-font-weight))
  (define flypy-single-font-weight (layer-font-weight config 'flypy-single-font-weight))
  (define flypy-double-font-weight (layer-font-weight config 'flypy-double-font-weight))
  (for/fold ([acc (hash)]) ([spec (in-list specs)])
    (define prefix (button-name (key-spec-letter spec)))
    (define-values (size bounds hint-extra) (size-for spec))
    (define-values (flypy-top flypy-bottom) (split-flypy (key-spec-flypy spec)))
    (define primary (theme-primary dark?))
    (define plain-layers (filter plain-text-layer? layers))
    (define foreground-layers
      (append
       (if (member 'abc layers) '(abc) '())
       (if (member 'cangjie layers) '(cangjie) '())
       (if (member 'flypy layers) '(flypy-top flypy-bottom) '())
       plain-layers
       (if (member 'symbol layers) '(symbol) '())))
    (define uppercase-layers
      (append
       (if (member 'abc layers) '(abc-uppercase) '())
       (if (member 'cangjie layers) '(cangjie) '())
       (if (member 'flypy layers) '(flypy-top flypy-bottom) '())
       plain-layers
       (if (member 'symbol layers) '(symbol) '())))
    (define entries
      (append
       (list
        (cons prefix
              (append
               (list (cons "action" (char-action (key-spec-letter spec)))
                     (cons "backgroundStyle" "alphabeticButtonBackgroundStyle"))
               (if bounds (list (cons "bounds" bounds)) '())
               (list (cons "capsLockedStateForegroundStyle" (layers->style-array prefix uppercase-layers))
                     (cons "foregroundStyle" (layers->style-array prefix foreground-layers))
                     (cons "hintStyle" (string-append prefix "HintStyle"))
                     (cons "size" size))
               (if (key-spec-swipe-down spec)
                   (list (cons "swipeDownAction" (key-spec-swipe-down spec)))
                   '())
               (list (cons "swipeUpAction" (key-spec-swipe-up spec))
                     (cons "uppercasedStateAction" (char-action (letter-upper (key-spec-letter spec))))
                     (cons "uppercasedStateForegroundStyle" (layers->style-array prefix uppercase-layers)))))
        (if (member 'abc layers)
            (cons (string-append prefix "AbcForegroundStyle")
                  (text-style dark?
                              #:text (key-spec-letter spec)
                              #:center (center-ref config 'abc)
                              #:font-size abc-font-size
                              #:secondary? abc-secondary?))
            #f)
        (if (member 'abc layers)
            (cons (string-append prefix "AbcUppercaseForegroundStyle")
                  (text-style dark?
                              #:text (letter-upper (key-spec-letter spec))
                              #:center (center-ref config 'abc)
                              #:font-size abc-font-size
                              #:secondary? abc-secondary?))
            #f)
        (if (member 'cangjie layers)
            (cons (string-append prefix "CangjieForegroundStyle")
                  (text-style dark?
                              #:text (key-spec-cangjie spec)
                              #:center (center-ref config 'cangjie)
                              #:font-size cangjie-font-size
                              #:font-weight cangjie-font-weight
                              #:secondary? cangjie-secondary?))
            #f)
        (if (member 'flypy layers)
            (cons (string-append prefix "FlypyTopForegroundStyle")
                  (if flypy-top
                      (text-style dark?
                                  #:text flypy-top
                                  #:center (center-ref config 'flypy-top)
                                  #:font-size flypy-double-font-size
                                  #:font-weight flypy-double-font-weight
                                  #:secondary? flypy-secondary?)
                      (text-style dark?
                                  #:text ""
                                  #:center (center-ref config 'flypy-single)
                                  #:font-size flypy-single-font-size
                                  #:font-weight flypy-single-font-weight
                                  #:secondary? flypy-secondary?)))
            #f)
        (if (member 'flypy layers)
            (cons (string-append prefix "FlypyBottomForegroundStyle")
                  (if flypy-top
                      (text-style dark?
                                  #:text flypy-bottom
                                  #:center (center-ref config 'flypy-bottom)
                                  #:font-size flypy-double-font-size
                                  #:font-weight flypy-double-font-weight
                                  #:secondary? flypy-secondary?)
                      (text-style dark?
                                  #:text flypy-bottom
                                  #:center (center-ref config 'flypy-single)
                                  #:font-size flypy-single-font-size
                                  #:font-weight flypy-single-font-weight
                                  #:secondary? flypy-secondary?)))
            #f)
        (cons (string-append prefix "HintForegroundStyle")
              (text-style dark? #:text (letter-upper (key-spec-letter spec)) #:font-size hint-font-size #:highlight? #f))
        (cons (string-append prefix "HintStyle")
              (append
               (object ["backgroundStyle" "alphabeticHintBackgroundStyle"]
                       ["foregroundStyle" (string-append prefix "HintForegroundStyle")])
               hint-style-extra
               hint-extra))
        (if (member 'symbol layers)
            (cons (string-append prefix "SymbolForegroundStyle")
                  (text-style dark?
                              #:text (key-spec-symbol spec)
                              #:center (center-ref config 'symbol)
                              #:font-size symbol-font-size
                              #:secondary? symbol-secondary?))
            #f)
        (cons (string-append prefix "UppercaseForegroundStyle")
              (object ["buttonStyleType" "text"]
                      ["fontSize" standard-uppercase-font-size]
                      ["highlightColor" primary]
                      ["normalColor" primary]
                      ["text" (letter-upper (key-spec-letter spec))])))
       (map (lambda (layer)
              (plain-text-layer-entry dark? spec config layer))
            plain-layers)))
    (for/fold ([inner acc]) ([entry (in-list (filter values entries))])
      (hash-set inner (car entry) (cdr entry)))))
