#lang racket/base

(require "keymaps.rkt")

(provide keyboard-layout-definitions
         keyboard-layout-definition-ref
         keyboard-dimensions
         keyboard-dimension-ref
         keyboard-dimension-id
         keyboard-dimension-skeleton
         keyboard-dimension-projection
         keyboard-dimension-interactions
         keyboard-dimension-target
         keyboard-legend-definitions
         keyboard-legend-definition-ref
         keyboard-legend-text
         keyboard-skeleton-definitions
         keyboard-skeleton-definition-ref
         keyboard-model-definitions
         keyboard-model-definition-ref
         keyboard-projection-definitions
         keyboard-projection-definition-ref
         keyboard-placement-definitions
         keyboard-placement-definition-ref
         keyboard-interaction-definitions
         keyboard-interaction-definition-ref)

(define-syntax-rule (define-catalog name (id body ...) ...)
  (define name
    '((id body ...) ...)))

(define (catalog-symbol value)
  (cond
    ((symbol? value) value)
    ((string? value) (string->symbol value))
    (else value)))

(define (catalog-definition-ref definitions id (default #f))
  (define id-symbol (catalog-symbol id))
  (define body
    (for/first ((clause (in-list definitions))
                #:when (eq? (car clause) id-symbol))
      (cdr clause)))
  (or body default))

(define standard-key-slots
  '((center #:font-size 25 #:role primary)
    (left #:font-size 10 #:role secondary)
    (right #:font-size 10 #:role secondary)
    (top #:font-size 10 #:role secondary)
    (bottom #:font-size 10 #:role secondary)
    (top-left #:font-size 10 #:role secondary)
    (top-right #:font-size 10 #:role secondary)
    (bottom-left #:font-size 10 #:role secondary)
    (bottom-right #:font-size 10 #:role secondary)))

(define keyboard-skeleton-definitions
  `((standard-26
     (columns 10)
     (rows
      (q w e r t y u i o p)
      (a s d f g h j k l)
      (z x c v b n m))
     (row-offsets 0 1/2 0)
     (slots ,standard-key-slots))
    (compact-14
     (columns 5)
     (rows
      (qw er ty ui op)
      (as df gh jk l)
      (zx cv bn m backspace))
     (row-offsets 0 0 0)
     (slots ,standard-key-slots))
    (compact-18
     (columns 7)
     (rows
      (q we rt y u io p)
      (a sd fg h jk l)
      (z xc v bn m))
     (row-offsets 0 0 0)
     (slots ,standard-key-slots))
    (compact-17
     (columns 6)
     (rows
      (a b c d e f)
      (g h i j k)
      (l m n o p q))
     (row-offsets 0 1/2 0)
     (slots ,standard-key-slots))
    (zhuyin
     (columns 10)
     (rows
      (bo de third-tone fourth-tone zhi second-tone light-tone a ai an)
      (po te ge ji chi zi yi o ei en)
      (mo ne ke qi shi ci wu e ao ang)
      (fo le he xi ri si yu eh ou eng))
     (row-offsets 0 0 0 0)
     (slots ,standard-key-slots))
    (standard-zhuyin
     (columns 11)
     (rows
      (one two three four five six seven eight nine zero minus)
      (q w e r t y u i o p)
      (a s d f g h j k l semicolon)
      (z x c v b n m comma period slash))
     (row-offsets 0 1/2 3/4 5/4)
     (aliases
      (one "1") (two "2") (three "3") (four "4") (five "5")
      (six "6") (seven "7") (eight "8") (nine "9") (zero "0")
      (minus "-") (semicolon ";") (comma ",") (period ".") (slash "/"))
     (slots ,standard-key-slots))))

(define keyboard-model-definitions keyboard-skeleton-definitions)

(define (keyboard-skeleton-definition-ref skeleton (default #f))
  (catalog-definition-ref keyboard-skeleton-definitions skeleton default))

(define keyboard-model-definition-ref keyboard-skeleton-definition-ref)

(define-catalog keyboard-projection-definitions
  (identity-26
   (summary "One schema key maps to one standard QWERTY slot.")
   (skeleton standard-26)
   (groups
    (q q) (w w) (e e) (r r) (t t) (y y) (u u) (i i) (o o) (p p)
    (a a) (s s) (d d) (f f) (g g) (h h) (j j) (k k) (l l)
    (z z) (x x) (c c) (v v) (b b) (n n) (m m)))
  (adjacent-qwerty-14
   (summary "Adjacent QWERTY pairs merge into the compact 14-key phone skeleton.")
   (skeleton compact-14)
   (groups
    (qw q w) (er e r) (ty t y) (ui u i) (op o p)
    (as a s) (df d f) (gh g h) (jk j k) (l l)
    (zx z x) (cv c v) (bn b n) (m m)))
  (adjacent-qwerty-18
   (summary "Screenshot-derived QWERTY groups merge into the compact 18-key phone skeleton.")
   (skeleton compact-18)
   (groups
    (q q) (we w e) (rt r t) (y y) (u u) (io i o) (p p)
    (a a) (sd s d) (fg f g) (h h) (jk j k) (l l)
    (z z) (xc x c) (v v) (bn b n) (m m)))
  (shuffle-17
   (summary "A shuffled 17-slot mobile projection using internal a-q codes.")
   (skeleton compact-17))
  (zhuyin-direct
   (summary "Bopomofo symbols map directly to the zhuyin skeleton.")
   (skeleton zhuyin))
  (standard-zhuyin-direct
   (summary "Da-Chien Bopomofo symbols map to the standard physical Zhuyin keyboard.")
   (skeleton standard-zhuyin)))

(define (keyboard-projection-definition-ref projection (default #f))
  (catalog-definition-ref keyboard-projection-definitions projection default))

(define-catalog keyboard-placement-definitions
  (standard-center
   (summary "Single primary legend centered on each key.")
   (positions (abc center))
   (fonts (abc 25 #:primary #:weight bold)))
  (standard-top-center
   (summary "Secondary Latin key on top with method-specific legend centered.")
   (positions (abc top))
   (fonts (abc 10 #:secondary)))
  (double-pinyin-center
   (summary "Double-pinyin finals centered below a small Latin key label.")
   (positions (abc top) (double-pinyin center))
   (fonts (abc 10 #:secondary) (double-pinyin 11 #:primary)))
  (compact-center
   (summary "Merged-key compact layouts use one centered primary label.")
   (positions (label center)))
  (split-flypy
   (summary "Flypy double labels split across center and bottom slots.")
   (positions (abc top) (flypy-single bottom) (flypy-top center) (flypy-bottom bottom))))

(define (keyboard-placement-definition-ref placement (default #f))
  (catalog-definition-ref keyboard-placement-definitions placement default))

(define-catalog keyboard-interaction-definitions
  (standard-mobile
   (summary "Default Yuanshu alphabetic keys with swipe-up symbol entry."))
  (no-swipe-down
   (summary "Generated layouts intentionally avoid swipe-down actions."))
  (compact-mobile
   (summary "Compact merged-key phone layouts with standard system last row."))
  (custom-mobile-pages
   (summary "Layout owns custom phone or iPad pages beyond the standard renderer."))
  (zhuyin-mobile
   (summary "Bopomofo mobile page with custom candidate, preedit, and toolbar chrome."))
  (standard-desktop
   (summary "Desktop-oriented physical keyboard without mobile gesture behavior.")))

(define (keyboard-interaction-definition-ref interaction (default #f))
  (catalog-definition-ref keyboard-interaction-definitions interaction default))

(struct keyboard-dimension
  (id
   skeleton
   projection
   interactions
   target)
  #:transparent)

(define-syntax-rule (define-keyboard-dimensions name
                      (id skeleton projection (interaction ...) target) ...)
  (define name
    (list
     (keyboard-dimension 'id 'skeleton 'projection '(interaction ...) 'target)
     ...)))

(define-keyboard-dimensions keyboard-dimensions
  (standard-26 standard-26 identity-26 (standard-mobile no-swipe-down) yuanshu)
  (compact-14 compact-14 adjacent-qwerty-14 (compact-mobile no-swipe-down) yuanshu)
  (compact-18 compact-18 adjacent-qwerty-18 (compact-mobile no-swipe-down) yuanshu)
  (shuffle-17 compact-17 shuffle-17 (custom-mobile-pages no-swipe-down) yuanshu)
  (zhuyin zhuyin zhuyin-direct (zhuyin-mobile custom-mobile-pages no-swipe-down) yuanshu)
  (standard-zhuyin standard-zhuyin standard-zhuyin-direct (standard-desktop) rime))

(define keyboard-dimension-by-id
  (for/hash ((dimension (in-list keyboard-dimensions)))
    (values (keyboard-dimension-id dimension) dimension)))

(define (keyboard-dimension-ref id)
  (hash-ref keyboard-dimension-by-id
            id
            (lambda ()
              (error 'keyboard-dimension-ref "unknown keyboard dimension: ~a" id))))

(define-syntax-rule (define-static-keyboard-layouts name
                      (id
                       #:name english-name chinese-name
                       #:summary summary
                       #:features (feature ...)
                       #:layer layer
                       #:phone-size phone-size
                       #:ipad-size ipad-size) ...)
  (define name
    '((id
       (meta
        (name english-name chinese-name)
        (summary summary)
        (features feature ...))
       (phone-layout
        (layers abc layer)
        (positions (abc top) (layer center))
        (fonts (abc 10 #:secondary) (layer phone-size #:primary)))
       (ipad-layout
        (layers abc layer)
        (size "1.1/16")
        (positions (abc top) (layer center))
        (fonts (abc 11 #:secondary) (layer ipad-size #:primary))))
      ...)))

;; Static upstream schemas do not have schema modules, so their reusable printed
;; keyboard legends live here. Generated schemas still own their local layouts.
(define-static-keyboard-layouts standard-keyboard-layout-definitions
  (wubi86
   #:name "Wubi 86" "五筆86"
   #:summary "Wubi 86 root legends on standard QWERTY rows."
   #:features ("Wubi root groups centered on letter keys"
               "Z key marks pinyin reverse lookup")
   #:layer wubi
   #:phone-size 12
   #:ipad-size 14)
  (stroke
   #:name "Stroke" "五筆畫"
   #:summary "Five-stroke legends and compatibility aliases."
   #:features ("Main h/s/p/n/z stroke keys"
               "Mac stroke alias keys j/k/l/u/i")
   #:layer stroke
   #:phone-size 22
   #:ipad-size 24)
  (double_pinyin_zrm
   #:name "Double Pinyin ZRM" "自然碼雙拼"
   #:summary "Ziranma double-pinyin final legends."
   #:features ("Ziranma finals centered on QWERTY keys")
   #:layer zrm
   #:phone-size 11
   #:ipad-size 13)
  (double_pinyin_abc
   #:name "Double Pinyin ABC" "智能ABC雙拼"
   #:summary "Intelligent ABC double-pinyin legends."
   #:features ("ABC finals and special initials centered on QWERTY keys")
   #:layer abc-dp
   #:phone-size 11
   #:ipad-size 13)
  (double_pinyin_mspy
   #:name "Double Pinyin MSPY" "微軟雙拼"
   #:summary "Microsoft double-pinyin final legends."
   #:features ("MSPY finals centered on QWERTY keys")
   #:layer mspy
   #:phone-size 11
   #:ipad-size 13)
  (double_pinyin_pyjj
   #:name "Double Pinyin PYJJ" "拼音加加雙拼"
   #:summary "Pinyin Jiajia double-pinyin final legends."
   #:features ("PYJJ finals centered on QWERTY keys")
   #:layer pyjj
   #:phone-size 11
   #:ipad-size 13)
  (double_pinyin_st
   #:name "Double Pinyin ST" "四通雙拼"
   #:summary "Stone double-pinyin final legends."
   #:features ("ST finals centered on QWERTY keys")
   #:layer st
   #:phone-size 11
   #:ipad-size 13))

(define (static-compact-keyboard-layout id english-name chinese-name summary variant)
  `(,id
    (meta
     (name ,english-name ,chinese-name)
     (summary ,summary)
     (features "Compact double-pinyin phone layout"
               "Standard iPad pinyin page and secondary pages"))
    (phone-layout ,variant)
    (ipad-layout standard-18)))

(define (double-pinyin-compact-layouts base-id english-name chinese-name)
  (list
   (static-compact-keyboard-layout
    (string->symbol (format "~a_14" base-id))
    (format "~a 14 Key" english-name)
    (format "~a 14鍵" chinese-name)
    (format "14-key compact Yuanshu keyboard layout for ~a." english-name)
    'pinyin-14)
   (static-compact-keyboard-layout
    (string->symbol (format "~a_shuffle_17" base-id))
    (format "~a Shuffle 17" english-name)
    (format "~a亂序 17鍵" chinese-name)
    (format "17-key shuffled Yuanshu keyboard layout for ~a." english-name)
    'shuffle-17)
   (static-compact-keyboard-layout
    (string->symbol (format "~a_18" base-id))
    (format "~a 18 Key" english-name)
    (format "~a 18鍵" chinese-name)
    (format "18-key compact Yuanshu keyboard layout for ~a." english-name)
    'zrm-18)))

(define double-pinyin-compact-keyboard-layout-definitions
  (append
   (double-pinyin-compact-layouts "double_pinyin_zrm" "Double Pinyin ZRM" "自然碼雙拼")
   (double-pinyin-compact-layouts "double_pinyin_abc" "Double Pinyin ABC" "智能ABC雙拼")
   (double-pinyin-compact-layouts "double_pinyin_mspy" "Double Pinyin MSPY" "微軟雙拼")
   (double-pinyin-compact-layouts "double_pinyin_pyjj" "Double Pinyin PYJJ" "拼音加加雙拼")
   (double-pinyin-compact-layouts "double_pinyin_st" "Double Pinyin ST" "四通雙拼")))

(define keyboard-layout-definitions
  (append standard-keyboard-layout-definitions
          double-pinyin-compact-keyboard-layout-definitions))

(define (keyboard-layout-definition-ref layout (default #f))
  (catalog-definition-ref keyboard-layout-definitions layout default))
