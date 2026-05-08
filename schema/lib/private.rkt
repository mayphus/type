#lang racket/base

;; Rime schema DSL language module.
;;
;; Usage:
;;   #lang s-exp "lib/lang.rkt"
;;
;;   (rime-schema flypy_14
;;     (name "14鍵")
;;     (artifacts yuanshu)
;;     (deps cangjie6)
;;     (static-files "rime_ice.dict.yaml")
;;     (static-dirs "rime_ice_dicts")
;;     (schema
;;       (version "0.1")
;;       (authors "dictionary import from iDvel/rime-ice")
;;       (description "...")
;;       (switches ...)
;;       (engine ...)
;;       (speller ...)
;;       (translator ...))
;;     (custom "flypy_14.custom.yaml"
;;       (includes yuanshu_common_patch yuanshu_reverse_lookup_patch)
;;       (version "0.1")
;;       (description "...")
;;       (patch "recognizer/patterns/reverse_lookup" "`[a-z]*'?$"))
;;     (yuanshu-skin flypy_14
;;       (meta ...)
;;       (phone-layout flypy-14)
;;       (ipad-layout standard-18)))

(require "../common.rkt"
         "../../yuanshu/patches.rkt"
         "../../lib/yaml/dsl.rkt"
         (for-syntax racket/base
                     racket/list
                     syntax/parse))

(provide (except-out (all-from-out racket/base) #%module-begin)
         #%datum
         (all-from-out "../common.rkt")
         (all-from-out "../../yuanshu/patches.rkt")
         (rename-out [rime-schema-module-begin #%module-begin])
         rime-schema
         keyboard
         include-ref
         switch
         engine
         speller
         translator
         section
         reverse-lookup
         recognizer
         preset-section
         switches
         pattern)

(define (dsl-name value)
  (cond
    [(symbol? value) (symbol->string value)]
    [(string? value) value]
    [else (error 'dsl-name "expected symbol or string, got ~v" value)]))

(define (dsl-sequence values)
  (apply sequence (map dsl-name values)))

(define (keyboard . _)
  (error 'keyboard "keyboard is only valid inside rime-schema"))

(define (schema-document #:id id
                         #:name name
                         #:version version
                         #:authors authors
                         #:description description
                         #:dependencies [dependencies '()]
                         . sections)
  (apply
   mapping
   (kv "schema"
       (apply
        mapping
        (append
         (list
          (kv "schema_id" (dsl-name id))
          (kv "name" name)
          (kv "version" version)
          (kv "author" (dsl-sequence authors))
          (kv "description" description))
         (if (null? dependencies)
             '()
             (list (kv "dependencies" (dsl-sequence dependencies)))))))
   sections))

(define (custom-patch . entries)
  (apply mapping entries))

(define (patch-field key value)
  (kv key
      (cond
        [(list? value) (dsl-sequence value)]
        [(or (symbol? value) (string? value)) (dsl-name value)]
        [else value])))

(define (schema-version value)
  (kv "schema/version" value))

(define (schema-description value)
  (kv "schema/description" value))

(define (include-ref target)
  (mapping (kv "__include" target)))

(define (switch name #:reset [reset #f] #:states states)
  (apply
   mapping
   (append
    (list (kv "name" (dsl-name name)))
    (if reset (list (kv "reset" reset)) '())
    (list (kv "states" (dsl-sequence states))))))

(define (engine #:processors [processors common-schema-processors]
                #:segmentors [segmentors common-schema-segmentors]
                #:translators translators
                #:filters [filters common-schema-filters])
  (kv "engine"
      (mapping
       (kv "processors" processors)
       (kv "segmentors" segmentors)
       (kv "translators" (dsl-sequence translators))
       (kv "filters" filters))))

(define (speller #:alphabet alphabet #:delimiter delimiter #:algebra algebra)
  (kv "speller"
      (mapping
       (kv "alphabet" alphabet)
       (kv "delimiter" delimiter)
       (kv "algebra" (apply sequence algebra)))))

(define (translator #:dictionary dictionary
                    #:prism prism
                    #:preedit-format [preedit-format #f])
  (apply
   section
   'translator
   (append
    (list
     (kv "dictionary" (dsl-name dictionary))
     (kv "prism" (dsl-name prism)))
    (if preedit-format
        (list (kv "preedit_format" preedit-format))
        '()))))

(define (section name . entries)
  (kv (dsl-name name) (apply mapping entries)))

(define (reverse-lookup #:dictionary dictionary
                        #:enable-completion [enable-completion #t]
                        #:prefix prefix
                        #:suffix suffix
                        #:tips tips
                        #:preedit-format preedit-format
                        #:comment-format comment-format)
  (kv "reverse_lookup"
      (mapping
       (kv "dictionary" (dsl-name dictionary))
       (kv "enable_completion" enable-completion)
       (kv "prefix" prefix)
       (kv "suffix" suffix)
       (kv "tips" tips)
       (kv "preedit_format" (apply sequence preedit-format))
       (kv "comment_format" (apply sequence comment-format)))))

(define (pattern name value)
  (kv (dsl-name name) value))

(define (recognizer #:import-preset [import-preset 'default] #:patterns [patterns '()])
  (kv "recognizer"
      (mapping
       (kv "import_preset" (dsl-name import-preset))
       (kv "patterns" (apply mapping patterns)))))

(define (preset-section name)
  (kv (dsl-name name) (mapping (kv "import_preset" "default"))))

(define (switches . values)
  (kv "switches" (apply sequence values)))

(define-syntax (rime-schema-module-begin stx)
  (syntax-parse stx
    [(_ body ...)
     #'(#%plain-module-begin body ...)]))

(begin-for-syntax
  (define (find-clause clauses tag)
    (for/first ([c (in-list clauses)]
                #:when (let ([lst (syntax->list c)])
                         (and lst
                              (pair? lst)
                              (eq? (syntax-e (car lst)) tag))))
      c))

  (define (clause-tag clause)
    (define lst (syntax->list clause))
    (and lst (pair? lst) (syntax-e (car lst))))

  (define (drop-clause-tags clauses tags)
    (filter (lambda (clause) (not (memq (clause-tag clause) tags))) clauses))

  (define (id-or-string->string stx)
    (define v (syntax-e stx))
    (cond
      [(symbol? v) (symbol->string v)]
      [(string? v) v]
      [else (raise-syntax-error #f "expected an identifier or string" stx)]))

  (define (clause-items->strings clause)
    (if clause
        (for/list ([item (in-list (cdr (syntax->list clause)))])
          (id-or-string->string item))
        '()))

  (define (string-expr ctx value)
    #`(symbol->string (quote #,(datum->syntax ctx (string->symbol value)))))

  (define (custom-clause-expr custom-cl)
    (if custom-cl
        (syntax-parse custom-cl
          [(_ filename clause ...)
           (define clauses (syntax->list #'(clause ...)))
           (define includes-cl (find-clause clauses 'includes))
           (define includes (clause-items->strings includes-cl))
           (define version-cl (find-clause clauses 'version))
           (define description-cl (find-clause clauses 'description))
           (define patch-clauses
             (filter (lambda (clause) (eq? (clause-tag clause) 'patch)) clauses))
           (define patch-expr
             #`(custom-patch
                #,@(if version-cl
                       (list #`(schema-version #,(cadr (syntax->list version-cl))))
                       '())
                #,@(if description-cl
                       (list #`(schema-description #,(cadr (syntax->list description-cl))))
                       '())
                #,@(for/list ([patch-cl (in-list patch-clauses)])
                     (define parts (syntax->list patch-cl))
                     (unless (= (length parts) 3)
                       (raise-syntax-error 'patch "expected (patch key value)" patch-cl))
                     #`(patch-field #,(cadr parts) #,(caddr parts)))))
	           #`(make-mobile-custom-file
	              filename
	              (list #,@(for/list ([include includes])
	                         (string-expr custom-cl include)))
	              #,patch-expr)])
        #'(hash)))

  (define (schema-clause-description schema-cl)
    (and schema-cl
         (let* ([items (syntax->list schema-cl)]
                [body (cdr items)]
                [description-cl (find-clause body 'description)])
           (and description-cl (cadr (syntax->list description-cl))))))

  (define (custom-clause-description custom-cl)
    (and custom-cl
         (syntax-parse custom-cl
           [(_ filename clause ...)
            (define clauses (syntax->list #'(clause ...)))
            (define description-cl (find-clause clauses 'description))
            (and description-cl (cadr (syntax->list description-cl)))])))

  (define (schema-clause-expr stx schema-id schema-name deps schema-cl)
    (if schema-cl
        (let* ([items (syntax->list schema-cl)]
               [body (cdr items)])
          (if (and (= (length body) 1)
                   (not (and (syntax->list (car body))
                             (pair? (syntax->list (car body))))))
              (car body)
              (let* ([version-cl (find-clause body 'version)]
                     [authors-cl (find-clause body 'authors)]
                     [description-cl (find-clause body 'description)]
                     [sections (drop-clause-tags body '(version authors description))])
                (unless version-cl
                  (raise-syntax-error 'schema "missing (version ...)" schema-cl))
                (unless authors-cl
                  (raise-syntax-error 'schema "missing (authors ...)" schema-cl))
                (unless description-cl
                  (raise-syntax-error 'schema "missing (description ...)" schema-cl))
                #`(schema-document
                   #:id '#,schema-id
                   #:name #,schema-name
                   #:version #,(cadr (syntax->list version-cl))
                   #:authors (list #,@(cdr (syntax->list authors-cl)))
                   #:description #,(cadr (syntax->list description-cl))
                   #:dependencies (list #,@(for/list ([dep deps])
                                             (string-expr schema-cl dep)))
                   #,@sections))))
        #'#f))

  (define (keyboard-layout-clause? clause)
    (define lst (syntax->list clause))
    (and lst
         (pair? lst)
         (memq (syntax-e (car lst)) '(keyboard keyboard-layout mobile-skin yuanshu-skin skin))))

  (define (keyboard-layout-id layout-cl)
    (define items (syntax->list layout-cl))
    (unless (>= (length items) 2)
      (raise-syntax-error 'keyboard-layout "missing layout id" layout-cl))
    (id-or-string->string (cadr items)))

  (define (clause? value tag)
    (and (pair? value) (eq? (car value) tag)))

  (define (datum-clause-body clauses tag)
    (cond
      [(for/first ([clause (in-list clauses)]
                   #:when (clause? clause tag))
         (cdr clause))]
      [else #f]))

  (define (datum-clause-value clauses tag)
    (define body (datum-clause-body clauses tag))
    (and body (pair? body) (car body)))

  (define (print-clause->layer clause)
    (cadr clause))

  (define (print-clause->enabled-layer clause)
    (case (print-clause->layer clause)
      [(flypy-single flypy-top flypy-bottom) 'flypy]
      [else (print-clause->layer clause)]))

  (define (print-clause->slot clause)
    (caddr clause))

  (define (print-clause-options clause)
    (cdddr clause))

  (define (option-ref options key [default #f])
    (cond
      [(memq key options) => (lambda (tail)
                               (if (pair? (cdr tail))
                                   (cadr tail)
                                   default))]
      [else default]))

  (define (option-present? options key)
    (and (memq key options) #t))

  (define (print-clause->font clause)
    (define layer (print-clause->layer clause))
    (define options (print-clause-options clause))
    (define font-size (option-ref options '#:font-size #f))
    (define role (option-ref options '#:role #f))
    (define weight (option-ref options '#:weight #f))
    (and font-size
         `(,layer
           ,font-size
           ,@(case role
               [(primary) '(#:primary)]
               [(secondary) '(#:secondary)]
               [else '()])
           ,@(if weight `(#:weight ,weight) '()))))

  (define (print-clause->position clause)
    `(,(print-clause->layer clause) ,(print-clause->slot clause)))

  (define (abstract-phone-layout model prints variant)
    (cond
      [(eq? model 'standard-26)
       (define layers (remove-duplicates (map print-clause->enabled-layer prints)))
       (define positions (map print-clause->position prints))
       (define fonts (filter values (map print-clause->font prints)))
       `(phone-layout
         (layers ,@layers)
         (positions ,@positions)
         ,@(if (null? fonts) '() `((fonts ,@fonts))))]
      [(and (eq? model 'compact-14) variant)
       `(phone-layout ,variant)]
      [(and (eq? model 'compact-18) variant)
       `(phone-layout ,variant)]
      [(and (eq? model 'compact-17) variant)
       `(phone-layout ,variant)]
      [(and (eq? model 'zhuyin) variant)
       `(phone-layout ,variant)]
      [else
       (error 'keyboard "unsupported keyboard model/variant: ~v ~v" model variant)]))

  (define (abstract-ipad-layout model ipad prints)
    (cond
      [(not ipad) '()]
      [(and (pair? ipad) (eq? (car ipad) 'raw))
       (list (cadr ipad))]
      [(symbol? ipad)
       (list `(ipad-layout ,ipad))]
      [(and (eq? model 'standard-26) (eq? ipad 'standard-26))
       (list `(ipad-layout
               (layers ,@(remove-duplicates (map print-clause->layer prints)))
               (positions ,@(map print-clause->position prints))
               (fonts ,@(filter values (map print-clause->font prints)))))]
      [else
       (list `(ipad-layout ,ipad))]))

  (define (abstract-keyboard-body datums)
    (define clauses datums)
    (define model (or (datum-clause-value clauses 'model) 'standard-26))
    (define variant (datum-clause-value clauses 'variant))
    (define ipad (datum-clause-value clauses 'ipad))
    (define prints (filter (lambda (clause) (clause? clause 'print)) clauses))
    (define meta-clauses (filter (lambda (clause) (clause? clause 'meta)) clauses))
    (append
     meta-clauses
     (list (abstract-phone-layout model prints variant))
     (abstract-ipad-layout model ipad prints)))

  (define (keyboard-layout-def layout-cl)
    (define items (syntax->list layout-cl))
    (define tag (syntax-e (car items)))
    (define layout-id (id-or-string->string (cadr items)))
    (define body
      (if (eq? tag 'keyboard)
          (abstract-keyboard-body (map syntax->datum (cddr items)))
          (map syntax->datum (cddr items))))
    #`(cons #,(string-expr layout-cl layout-id) '#,body))

)

(define-syntax (rime-schema stx)
  (syntax-parse stx
    [(_ schema-id:id clause ...)
     (define clauses (syntax->list #'(clause ...)))
     (define name-cl (find-clause clauses 'name))
     (define artifacts-cl
       (or (find-clause clauses 'artifacts)
           (find-clause clauses 'artifact)))
     (define mobile-only-cl (find-clause clauses 'mobile-only))
     (define keyboard-layouts-cl
       (or (find-clause clauses 'keyboard-layouts)
           (find-clause clauses 'mobile-skins)
           (find-clause clauses 'keyboard-layout)
           (find-clause clauses 'mobile-skin)
           (find-clause clauses 'yuanshu-skin)
           (find-clause clauses 'skin)))
     (define keyboard-layout-clauses
       (filter keyboard-layout-clause? clauses))
     (define deps-cl (find-clause clauses 'deps))
     (define files-cl (find-clause clauses 'static-files))
     (define dirs-cl (find-clause clauses 'static-dirs))
     (define schema-cl (find-clause clauses 'schema))
     (define custom-cl (find-clause clauses 'custom))

     (unless name-cl
       (raise-syntax-error 'rime-schema "missing (name ...)" stx))
     (unless (or schema-cl custom-cl keyboard-layout-clauses)
       (raise-syntax-error 'rime-schema "missing (schema ...), (custom ...), or (keyboard-layout ...)" stx))

     (define schema-name (cadr (syntax->list name-cl)))
     (define artifacts
       (cond
         [artifacts-cl (clause-items->strings artifacts-cl)]
         [mobile-only-cl '("yuanshu")]
         [else '("rime" "yuanshu")]))
     (define explicit-keyboard-layouts
       (and keyboard-layouts-cl
            (not (keyboard-layout-clause? keyboard-layouts-cl))
            (clause-items->strings keyboard-layouts-cl)))
     (define embedded-keyboard-layouts
       (map keyboard-layout-id keyboard-layout-clauses))
     (define embedded-keyboard-layout-defs
       (map keyboard-layout-def keyboard-layout-clauses))
     (define keyboard-layouts
       (if explicit-keyboard-layouts
           explicit-keyboard-layouts
           embedded-keyboard-layouts))
     (define deps (clause-items->strings deps-cl))
     (define static-files (clause-items->strings files-cl))
     (define static-dirs (clause-items->strings dirs-cl))
     (define custom-expr (custom-clause-expr custom-cl))
     (define schema-doc (schema-clause-expr stx #'schema-id schema-name deps schema-cl))
     (define description-expr
       (or (schema-clause-description schema-cl)
           (custom-clause-description custom-cl)
           schema-name))
	     (define schema-expr
	       (if schema-cl
	           #`(yaml-file #,(string-expr stx (string-append (symbol->string (syntax-e #'schema-id)) ".schema.yaml"))
	                        #,schema-doc)
	           #'(hash)))

	     #`(begin
         (define chinese-name #,(string-expr stx (syntax-e schema-name)))
         (define schema-summary #,description-expr)
         (define schema-artifacts (list #,@(for/list ([artifact artifacts])
                                             (string-expr stx artifact))))
	         (define keyboard-layouts (list #,@(for/list ([layout keyboard-layouts])
	                                            (string-expr stx layout))))
         (define keyboard-layout-defs
           (list #,@embedded-keyboard-layout-defs))
         (define mobile-only? (not (member "rime" schema-artifacts)))
         (define mobile-skins keyboard-layouts)
         (define mobile-skin-defs keyboard-layout-defs)
	         (define schema-deps (list #,@(for/list ([dep deps])
	                                        (string-expr stx dep))))
	         (define static-dep-files (list #,@(for/list ([file static-files])
	                                             (string-expr stx file))))
	         (define static-dep-dirs (list #,@(for/list ([dir static-dirs])
	                                            (string-expr stx dir))))
         (define config-files
           (bundle
            #,schema-expr
            #,custom-expr))
         (provide config-files
                  schema-summary
                  schema-artifacts
                  keyboard-layouts
                  keyboard-layout-defs
                  mobile-only?
                  mobile-skins
                  mobile-skin-defs
                  schema-deps
                  static-dep-files
                  static-dep-dirs
                  chinese-name))]))
