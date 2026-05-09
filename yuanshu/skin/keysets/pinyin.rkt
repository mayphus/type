#lang racket/base

(require (for-syntax racket/base
                     syntax/parse)
         "../../../keyboard/legends.rkt"
         "../core/dsl.rkt"
         "../core/visual-policy.rkt"
         "actions.rkt")

(provide hybrid-letter-specs
         key-spec-letter
         key-spec-cangjie
         key-spec-flypy
         key-spec-symbol
         key-spec-layer-text
         key-spec-swipe-up
         key-spec-swipe-down
         find-hybrid-letter-spec
         default-legend-centers)

(struct key-spec (letter cangjie flypy symbol layers swipe-up swipe-down) #:transparent)

(define-syntax (define-letter-specs stx)
  (define-splicing-syntax-class maybe-swipe-down
    (pattern (~seq #:swipe-down swipe-down:expr))
    (pattern (~seq) #:attr swipe-down #'#f))
  (syntax-parse stx
    [(_ name:id
        [letter:id
         #:cangjie cangjie:expr
         #:flypy flypy:expr
         #:symbol symbol:expr
         #:swipe-up swipe-up:expr
         maybe:maybe-swipe-down] ...)
     #'(define name
         (list
          (key-spec (symbol->string 'letter)
                    cangjie
                    flypy
                    symbol
                    (hash 'wubi (keyboard-legend-text 'wubi 'letter)
                          'stroke (keyboard-legend-text 'stroke 'letter)
                          'zrm (keyboard-legend-text 'zrm 'letter)
                          'abc-dp (keyboard-legend-text 'abc-dp 'letter)
                          'mspy (keyboard-legend-text 'mspy 'letter)
                          'pyjj (keyboard-legend-text 'pyjj 'letter)
                          'st (keyboard-legend-text 'st 'letter)
                          'jyutping (keyboard-legend-text 'jyutping 'letter))
                    swipe-up
                    maybe.swipe-down)
          ...))]))

(define (num lexeme)
  (json-number lexeme))

(define default-legend-centers
  (hash 'abc (key-note-position 'right)
        'cangjie (key-note-position 'top-left)
        'symbol (key-note-position 'top-right)
        'wubi (key-note-position 'center)
        'stroke (key-note-position 'center)
        'zrm (key-note-position 'center)
        'abc-dp (key-note-position 'center)
        'mspy (key-note-position 'center)
        'pyjj (key-note-position 'center)
        'st (key-note-position 'center)
        'jyutping (key-note-position 'center)
        'flypy-single (key-note-position 'bottom)
        'flypy-top (key-note-position 'center)
        'flypy-bottom (key-note-position 'bottom)))

(define-letter-specs hybrid-letter-specs
  [q #:cangjie "手" #:flypy "iu" #:symbol "1" #:swipe-up (char-action "1")]
  [w #:cangjie "田" #:flypy "ei" #:symbol "2" #:swipe-up (char-action "2")]
  [e #:cangjie "水" #:flypy "e" #:symbol "3" #:swipe-up (char-action "3")]
  [r #:cangjie "口" #:flypy "uan" #:symbol "4" #:swipe-up (char-action "4")]
  [t #:cangjie "廿" #:flypy "ue\nve" #:symbol "5" #:swipe-up (char-action "5")]
  [y #:cangjie "卜" #:flypy "un" #:symbol "6" #:swipe-up (char-action "6")]
  [u #:cangjie "山" #:flypy "sh" #:symbol "7" #:swipe-up (char-action "7")]
  [i #:cangjie "戈" #:flypy "ch" #:symbol "8" #:swipe-up (char-action "8")]
  [o #:cangjie "人" #:flypy "uo" #:symbol "9" #:swipe-up (char-action "9")]
  [p #:cangjie "心" #:flypy "ie" #:symbol "0" #:swipe-up (char-action "0")]
  [a #:cangjie "日" #:flypy "a" #:symbol "`" #:swipe-up (char-action "`")]
  [s #:cangjie "尸" #:flypy "ong\niong" #:symbol "/" #:swipe-up (char-action "/")]
  [d #:cangjie "木" #:flypy "ai" #:symbol ":" #:swipe-up (char-action ":")]
  [f #:cangjie "火" #:flypy "en" #:symbol ";" #:swipe-up (char-action ";")]
  [g #:cangjie "土" #:flypy "eng" #:symbol "(" #:swipe-up (char-action "(")]
  [h #:cangjie "的" #:flypy "ang" #:symbol "[" #:swipe-up (char-action "[")]
  [j #:cangjie "十" #:flypy "an" #:symbol "~" #:swipe-up (char-action "~")]
  [k #:cangjie "大" #:flypy "ing\nuai" #:symbol "@" #:swipe-up (char-action "@")]
  [l #:cangjie "中" #:flypy "iang\nuang" #:symbol "\"" #:swipe-up (char-action "\"")]
  [z #:cangjie "片" #:flypy "ou" #:symbol "," #:swipe-up (char-action ",")]
  [x #:cangjie "止" #:flypy "ia\nua" #:symbol "." #:swipe-up (char-action ".")]
  [c #:cangjie "金" #:flypy "ao" #:symbol "#" #:swipe-up (char-action "#")]
  [v #:cangjie "女" #:flypy "zh\nui" #:symbol "\\" #:swipe-up (char-action "\\")]
  [b #:cangjie "月" #:flypy "in" #:symbol "?" #:swipe-up (char-action "?")]
  [n #:cangjie "弓" #:flypy "iao" #:symbol "!" #:swipe-up (char-action "!")]
  [m #:cangjie "一" #:flypy "ian" #:symbol "…" #:swipe-up (symbol-action "…")])

(define (find-hybrid-letter-spec letter)
  (for/first ([spec (in-list hybrid-letter-specs)]
              #:when (string=? (key-spec-letter spec) letter))
    spec))

(define (key-spec-layer-text spec layer)
  (case layer
    [(abc) (key-spec-letter spec)]
    [(abc-uppercase) (string-upcase (key-spec-letter spec))]
    [(cangjie) (key-spec-cangjie spec)]
    [(flypy) (key-spec-flypy spec)]
    [(symbol) (key-spec-symbol spec)]
    [else (hash-ref (key-spec-layers spec) layer "")]))
