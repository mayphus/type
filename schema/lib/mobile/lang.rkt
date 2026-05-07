#lang racket/base

;; yuanshu-skin DSL language module
;;
;; Usage in skin files:
;;   #lang s-exp "lib/lang.rkt"
;;
;;   (skin <slug>
;;     (triggers <schema-id> ... | default)
;;     (meta
;;       (name "<english>" "<chinese>")
;;       (summary "<description>")
;;       (features "<feature>" ...))
;;     (phone-layout <type>)
;;     (ipad-layout <type>))
;;
;; ─── phone-layout ───────────────────────────────────────────────────────────
;;
;;   Prebuilt (self-contained bundles — no ipad-layout needed for marked ones):
;;     flypy         — standard Flypy double-pinyin, standard 10/9/8 key rows
;;     cangjie6      — Cangjie 6 legends on standard QWERTY rows
;;     hybrid        — Cangjie + Flypy combined on one phone layout
;;     pinyin-14     — Full-pinyin 14-key merged layout
;;     flypy-14      — Flypy 14-key merged layout
;;     flypy-18      — Flypy 18-key merged layout (7-6-7 rows)
;;     zrm-18        — ZRM 18-key merged layout
;;     zrm-18-aux    — ZRM 18-key auxiliary layout
;;     shuffle-17    — 17-key shuffle layout (includes custom iPad pages) *
;;     bopomofo      — Bopomofo (注音) layout *
;;     soft46        — Soft 46-key layout *
;;     (* these prebuilts include their own iPad pages)
;;
;;   Standard-pinyin customization form — use when you want QWERTY rows with
;;   custom legend layers, positions, or font sizes:
;;     (phone-layout
;;       (layers <layer-id> ...)          ; e.g. abc flypy cangjie symbol
;;       (centers                          ; optional: override legend positions
;;         [<layer-id> <x> <y>] ...)
;;       (fonts                            ; optional: override font sizes/styles
;;         [<layer-id> <size> <#:primary|#:secondary>? <#:weight bold>?] ...))
;;
;;   Custom template form — for flypy18-compatible layouts with a fully custom
;;   keyboard grid and button set (advanced use):
;;     (phone-layout
;;       (template <make-fn>)              ; e.g. make-flypy18-files
;;       (grid [<cell-id> ...] ...)        ; keyboard row/cell layout
;;       (buttons <button-spec-expr> ...)  ; list of button data
;;       (fonts <detail-size>))            ; hint text font size
;;
;; ─── ipad-layout ────────────────────────────────────────────────────────────
;;
;;   Prebuilt:
;;     standard-18   — full standard 18-column iPad QWERTY with number row
;;
;;   Customization form:
;;     (ipad-layout
;;       (layers <layer-id> ...)           ; legend layers to render
;;       (size "<fraction-string>")        ; button width, e.g. "1.1/16"
;;       (centers                          ; optional: override legend positions
;;         [<layer-id> <x> <y>] ...)
;;       (fonts                            ; optional: override font sizes/styles
;;         [<layer-id> <size> <#:primary|#:secondary>? <#:weight bold>?] ...))
;;
;; ─── theme ──────────────────────────────────────────────────────────────────
;;
;;   Optional clause to override accent colors for customization-form layouts.
;;   (Prebuilt bundles like flypy-18 are pre-computed and unaffected.)
;;
;;     (theme
;;       (primary "<light-hex>" "<dark-hex>")   ; main text / icon color
;;       (secondary "<light-hex>" "<dark-hex>")) ; dim label color

(require racket/hash
         "core/dsl.rkt"
         "core/docs.rkt"
         "core/preview.rkt"
         "core/preview-svg.rkt"
         "presets/standard.rkt"
         "keysets/pinyin-common.rkt"
         "layouts/base-page.rkt"
         "layouts/standard-phone-pinyin-page.rkt"
         "layouts/standard-ipad-page.rkt"
         "layouts/hybrid-iphone-pinyin-page.rkt"
         "layouts/pinyin-14-page.rkt"
         "layouts/flypy-14-page.rkt"
         "layouts/flypy-18-page.rkt"
         "layouts/zrm-18-page.rkt"
         "layouts/zrm-18-aux-page.rkt"
         "layouts/flypy18-page.rkt"
         "layouts/flypy18-bases.rkt"
         "layouts/shuffle-17-pages.rkt"
         "layouts/bopomofo-page.rkt"
         "layouts/soft46-page.rkt"
         (for-syntax racket/base
                     syntax/parse))

;; Re-export racket/base (minus #%module-begin which we replace) and all skin
;; library bindings, so skin modules get everything automatically.
(provide (except-out (all-from-out racket/base) #%module-begin)
         #%datum
         (all-from-out racket/hash
                       "core/dsl.rkt"
                       "core/docs.rkt"
                       "core/preview.rkt"
                       "core/preview-svg.rkt"
                       "presets/standard.rkt"
                       "keysets/pinyin-common.rkt"
                       "layouts/base-page.rkt"
                       "layouts/standard-phone-pinyin-page.rkt"
                       "layouts/standard-ipad-page.rkt"
                       "layouts/hybrid-iphone-pinyin-page.rkt"
                       "layouts/pinyin-14-page.rkt"
                       "layouts/flypy-14-page.rkt"
                       "layouts/flypy-18-page.rkt"
                       "layouts/zrm-18-page.rkt"
                       "layouts/zrm-18-aux-page.rkt"
                       "layouts/flypy18-page.rkt"
                       "layouts/flypy18-bases.rkt"
                       "layouts/shuffle-17-pages.rkt"
                       "layouts/bopomofo-page.rkt"
                       "layouts/soft46-page.rkt")
         (rename-out [yuanshu-module-begin #%module-begin])
         skin)

;;; ============================================================
;;; #%module-begin — thin wrapper; all real work is in `skin`
;;; ============================================================

(define-syntax (yuanshu-module-begin stx)
  (syntax-parse stx
    [(_ body ...)
     #'(#%plain-module-begin body ...)]))

;;; ============================================================
;;; Compile-time helpers
;;; ============================================================

(begin-for-syntax

  ;; Find the first clause whose car matches tag
  (define (find-clause clauses tag)
    (for/first ([c clauses]
                #:when (let ([lst (syntax->list c)])
                         (and lst
                              (not (null? lst))
                              (eq? (syntax->datum (car lst)) tag))))
      c))

  ;; Produce (json-number "N") from a Racket number literal.
  ;; Exact integers stay as integers (11 → "11"), inexact floats stay as-is.
  (define (num->jn n-stx)
    (define n (syntax->datum n-stx))
    (unless (real? n) (raise-syntax-error #f "expected a number" n-stx))
    (define s (if (and (exact? n) (integer? n))
                  (number->string n)
                  (number->string (if (exact? n) (exact->inexact n) n))))
    (quasisyntax/loc n-stx (json-number #,s)))

  ;; Expand (centers [layer x y] ...) → list of k-v syntax pairs
  (define (expand-centers-kvs centers-stx)
    (define entries (cdr (syntax->list centers-stx)))
    (apply append
           (for/list ([entry entries])
             (syntax-parse entry
               [[layer:id cx:number cy:number]
                (list #`'layer
                      #`(object ["x" #,(num->jn #'cx)]
                                ["y" #,(num->jn #'cy)]))]))))

  ;; Expand (fonts [layer size opts...] ...) → flat kv list for `hash`
  (define (expand-font-kvs fonts-stx)
    (define entries (cdr (syntax->list fonts-stx)))
    (apply append
           (for/list ([entry entries])
             (syntax-parse entry
               [[layer:id size:number opt ...]
                (define prefix (symbol->string (syntax->datum #'layer)))
                (define opts   (map syntax->datum (syntax->list #'(opt ...))))
                ;; font-size is always present
                (define kvs
                  (list #`'#,(string->symbol (string-append prefix "-font-size"))
                        (num->jn #'size)))
                ;; #:primary / #:secondary color role
                (define role-kvs
                  (cond
                    [(memv '#:primary opts)
                     (list #`'#,(string->symbol (string-append prefix "-secondary?")) #'#f)]
                    [(memv '#:secondary opts)
                     (list #`'#,(string->symbol (string-append prefix "-secondary?")) #'#t)]
                    [else '()]))
                (define kvs+role (append kvs role-kvs))
                ;; #:weight bold
                (define wi (memv '#:weight opts))
                (if wi
                    (append kvs+role
                            (list #`'#,(string->symbol (string-append prefix "-font-weight"))
                                  (datum->syntax entry (symbol->string (cadr wi)))))
                    kvs+role)]))))

  ;; Expand (meta ...) → make-skin-meta call
  (define (expand-meta meta-stx slug-str)
    (define sub      (cdr (syntax->list meta-stx)))
    (define name-cl  (find-clause sub 'name))
    (define sum-cl   (find-clause sub 'summary))
    (define feat-cl  (find-clause sub 'features))
    (define names    (if name-cl (cdr (syntax->list name-cl)) '()))
    (define en       (if (>= (length names) 1) (car  names) #'""))
    (define zh       (if (>= (length names) 2) (cadr names) #'""))
    (define summary  (if sum-cl  (cadr (syntax->list sum-cl)) #'""))
    (define features (if feat-cl (cdr  (syntax->list feat-cl)) '()))
    #`(make-skin-meta
       #:slug         #,(datum->syntax meta-stx slug-str)
       #:english-name #,en
       #:chinese-name #,zh
       #:summary      #,summary
       #:features     (list #,@features)))

  ;; Expand (grid [cell ...] ...) → array of HStack objects
  (define (expand-grid grid-stx)
    (define rows (cdr (syntax->list grid-stx)))
    #`(array
       #,@(for/list ([row rows])
            #`(object ["HStack"
                       (object ["subviews"
                                (array #,@(for/list ([cell (syntax->list row)])
                                            #`(object ["Cell" #,(symbol->string (syntax->datum cell))])))])]))))

  ;; Expand (buttons expr ...) → (list expr ...)
  (define (expand-buttons-list buttons-stx)
    #`(list #,@(cdr (syntax->list buttons-stx))))

  ;; Expand (phone-layout ...) → file hash expression.
  ;; Form 1: (phone-layout <type:id>) — shorthand for prebuilt or standard pinyin layouts.
  ;; Form 2: (phone-layout (template <id>) (grid ...) (buttons ...) (fonts ...)) — detailed template.
  ;; Form 3: (phone-layout (layers ...) (centers ...) (fonts ...)) — standard layout config.
  (define (expand-phone phone-stx)
    (syntax-parse phone-stx
      [(_ type:id)
       (define t (syntax->datum #'type))
       ;; Pre-built file collections (phone-only or phone+iPad bundled)
       (define prebuilt
         (case t
           [(hybrid)       'iphone-pinyin-files]
           [(pinyin-14)    'pinyin-14-iphone-pinyin-files]
           [(flypy-14)     'flypy-14-iphone-pinyin-files]
           [(flypy-18)     'flypy-18-iphone-pinyin-files]
           [(zrm-18)       'zrm-18-iphone-pinyin-files]
           [(zrm-18-aux)   'zrm-18-aux-iphone-pinyin-files]
           [(shuffle-17)   'shuffle-17-pinyin-files]
           [(bopomofo)     'bopomofo-pinyin-files]
           [(soft46)       'soft46-pinyin-files]
           [else #f]))
       (if prebuilt
           (datum->syntax phone-stx prebuilt)
           (let ()
             (define make-fn
               (case t
                 [(flypy)    'make-flypy-phone-files]
                 [(cangjie6) 'make-cangjie6-phone-files]
                 [else (raise-syntax-error
                        'phone-layout
                        (format "unknown type '~a'; supported: flypy cangjie6 hybrid pinyin-14 flypy-14 flypy-18 zrm-18 zrm-18-aux shuffle-17 bopomofo"
                                t)
                        phone-stx)]))
             #`(#,(datum->syntax phone-stx make-fn)
                (lambda (dark? portrait?)
                  (cond
                    [(and (not dark?) portrait?)       standard-phone-portrait-light-base]
                    [(and dark?       portrait?)       standard-phone-portrait-dark-base]
                    [(and (not dark?) (not portrait?)) standard-phone-landscape-light-base]
                    [else                              standard-phone-landscape-dark-base])))))]
      [(_ clause ...)
       (define sub (syntax->list #'(clause ...)))
       (define template-cl (find-clause sub 'template))
       (if template-cl
           (let ()
             (define template-id (cadr (syntax->list template-cl)))
             (define grid-cl     (find-clause sub 'grid))
             (define buttons-cl  (find-clause sub 'buttons))
             (define fonts-cl    (find-clause sub 'fonts))
             (define grid-expr    (if grid-cl (expand-grid grid-cl) #'#f))
             (define buttons-expr (if buttons-cl (expand-buttons-list buttons-cl) #'#f))
             (define detail-font-size (if fonts-cl (cadr (syntax->list fonts-cl)) #'8))
             #`(#,template-id
                #:portrait-name  "pinyinPortrait"
                #:landscape-name "pinyinLandscape"
                #:base-page
                (lambda (dark? portrait?)
                  (cond
                    [(and (not dark?) portrait?)       flypy18-portrait-light-base]
                    [(and dark?       portrait?)       flypy18-portrait-dark-base]
                    [(and (not dark?) (not portrait?)) flypy18-landscape-light-base]
                    [else                              flypy18-landscape-dark-base]))
                #:keyboard-layout #,grid-expr
                #:button-specs    #,buttons-expr
                #:detail-font-size #,detail-font-size))
           (let ()
             (define layers-cl  (find-clause sub 'layers))
             (define centers-cl (find-clause sub 'centers))
             (define fonts-cl   (find-clause sub 'fonts))
             (define layer-syms (if layers-cl (cdr (syntax->list layers-cl)) '(abc flypy)))
             (define centers-expr
               (if centers-cl
                   #`(hash-set* phone-legend-centers #,@(expand-centers-kvs centers-cl))
                   #'phone-legend-centers))
             (define font-kvs
               (if fonts-cl (expand-font-kvs fonts-cl) '()))
             #`(make-standard-phone-pinyin-files
                (lambda (dark? portrait?)
                  (cond
                    [(and (not dark?) portrait?)       standard-phone-portrait-light-base]
                    [(and dark?       portrait?)       standard-phone-portrait-dark-base]
                    [(and (not dark?) (not portrait?)) standard-phone-landscape-light-base]
                    [else                              standard-phone-landscape-dark-base]))
                (hash 'enabled-layers (list #,@(for/list ([l layer-syms]) #`'#,l))
                      'size-for       button-size+bounds
                      'centers        #,centers-expr
                      'hint-style-extra (list (cons "size" hint-size))
                      ;; Defaults
                      'abc-font-size  10
                      'abc-secondary? #t
                      'cangjie-font-size 14
                      'cangjie-font-weight "bold"
                      'symbol-font-size 10
                      'flypy-single-font-size (json-number "13.5")
                      'flypy-single-font-weight "bold"
                      'flypy-double-font-size 10
                      'flypy-double-font-weight "bold"
                      ;; User overrides
                      #,@font-kvs))))]))

  ;; Expand (theme ...) → list of parameterize bindings
  ;; (theme (primary "#light" "#dark") (secondary "#light" "#dark"))
  (define (expand-theme-bindings theme-stx)
    (define sub (cdr (syntax->list theme-stx)))
    (define primary-cl   (find-clause sub 'primary))
    (define secondary-cl (find-clause sub 'secondary))
    (append
     (if primary-cl
         (let ([args (cdr (syntax->list primary-cl))])
           (list #`[current-primary-light  #,(car args)]
                 #`[current-primary-dark   #,(cadr args)]))
         '())
     (if secondary-cl
         (let ([args (cdr (syntax->list secondary-cl))])
           (list #`[current-secondary-light #,(car args)]
                 #`[current-secondary-dark  #,(cadr args)]))
         '())))

  ;; Expand (ipad-layout ...) → file hash expression.
  ;; Shorthand: (ipad-layout standard-18) → ipad-pinyin-files
  ;; Full form: (ipad-layout (layers ...) (size ...) (centers ...) (fonts ...))
  ;;            → make-standard-ipad-pinyin-files call
  (define (expand-ipad ipad-stx)
    (define sub (cdr (syntax->list ipad-stx)))
    ;; Shorthand: single symbol standard-18
    (if (and (= (length sub) 1)
             (eq? (syntax->datum (car sub)) 'standard-18))
        #'ipad-pinyin-files
        (let ()
          (define layers-cl  (find-clause sub 'layers))
          (define size-cl    (find-clause sub 'size))
          (define centers-cl (find-clause sub 'centers))
          (define fonts-cl   (find-clause sub 'fonts))
          (define layer-syms (if layers-cl (cdr (syntax->list layers-cl)) '()))
          (define size-str   (if size-cl (cadr (syntax->list size-cl)) #'"1/1"))
          (define centers-expr
            (if centers-cl
                #`(hash-set* default-legend-centers #,@(expand-centers-kvs centers-cl))
                #'default-legend-centers))
          (define font-kvs
            (if fonts-cl (expand-font-kvs fonts-cl) '()))
          #`(make-standard-ipad-pinyin-files
             #:letter-config
             ;; Racket's hash uses the last value for duplicate keys, so defaults
             ;; come first and user-specified values (font-kvs) override them.
             (hash 'enabled-layers  (list #,@(for/list ([l layer-syms]) #`'#,l))
                   'size-for        (lambda (_spec) (values (object ["width" #,size-str]) #f '()))
                   'centers         #,centers-expr
                   'hint-style-extra '()
                   ;; Required defaults for all font layers
                   'abc-font-size          (json-number "11")
                   'cangjie-font-size      (json-number "18")
                   'symbol-font-size       (json-number "10")
                   'flypy-single-font-size (json-number "18.5")
                   'flypy-double-font-size (json-number "13")
                   ;; User-specified overrides
                   #,@font-kvs)))))


) ; end begin-for-syntax

;;; ============================================================
;;; skin — top-level form; emits all defines + provide
;;; ============================================================

(define-syntax (skin stx)
  (syntax-parse stx
    [(_ slug:id clause ...)
     (define clauses  (syntax->list #'(clause ...)))
     (define slug-str (symbol->string (syntax->datum #'slug)))

     (define triggers-cl (find-clause clauses 'triggers))
     (define meta-cl     (find-clause clauses 'meta))
     (define phone-cl    (find-clause clauses 'phone-layout))
     (define ipad-cl     (find-clause clauses 'ipad-layout))
     (define theme-cl    (find-clause clauses 'theme))

     ;; Build trigger-schemas expression.
     ;; (triggers default) → 'default symbol; otherwise → list of schema ID strings.
     (define raw-triggers
       (if triggers-cl (cdr (syntax->list triggers-cl)) '()))
     (define trigger-expr
       (if (and (= (length raw-triggers) 1)
                (eq? (syntax->datum (car raw-triggers)) 'default))
           #'(quote default)
           (with-syntax ([(tstr ...)
                          (for/list ([t raw-triggers])
                            (datum->syntax t (symbol->string (syntax->datum t))))])
             #'(list tstr ...))))

     (define phone-expr (if phone-cl (expand-phone phone-cl) #'(hash)))
     (define ipad-expr  (if ipad-cl  (expand-ipad  ipad-cl)  #'(hash)))
     (define preview-bundle-expr
       #`(bundle (make-standard-skin-files -phone- -ipad-)))
     (define bundle-expr
       #`(bundle #,preview-bundle-expr
                 (if -meta- (make-skin-doc-files -meta- skin-preview-spec) (hash))))
     (define skin-preview-files-expr
       (if theme-cl
           #`(let ([-phone- #,phone-expr]
                   [-ipad-  #,ipad-expr])
               (parameterize (#,@(expand-theme-bindings theme-cl))
                 #,preview-bundle-expr))
           #`(let ([-phone- #,phone-expr]
                   [-ipad-  #,ipad-expr])
               #,preview-bundle-expr)))
     (define skin-preview-spec-expr
       #`(preview-spec-from-files skin-preview-files))
     (define skin-files-expr
       (if theme-cl
           #`(let ([-phone- #,phone-expr]
                   [-ipad-  #,ipad-expr])
               (parameterize (#,@(expand-theme-bindings theme-cl))
                 #,bundle-expr))
           #`(let ([-phone- #,phone-expr]
                   [-ipad-  #,ipad-expr])
               #,bundle-expr)))
     #`(begin
         (define trigger-schemas #,trigger-expr)
         (define -meta-
           #,(if meta-cl (expand-meta meta-cl slug-str) #'#f))
         (define chinese-name (if -meta- (skin-meta-chinese-name -meta-) ""))
         (define english-name (if -meta- (skin-meta-english-name -meta-) ""))
         (define skin-preview-files #,skin-preview-files-expr)
         (define skin-preview-spec #,skin-preview-spec-expr)
         (define skin-preview-svgs (preview-spec->svgs skin-preview-spec))
         (define skin-files #,skin-files-expr)
         (provide skin-preview-files skin-preview-spec skin-preview-svgs skin-files trigger-schemas chinese-name english-name))]))
