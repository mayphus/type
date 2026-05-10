#lang racket/base

(require "../lib/lang.rkt"
         (for-syntax racket/base
                     racket/list
                     racket/syntax
                     syntax/parse))

(provide flypy-schema
         flypy-family)

(begin-for-syntax
  (define (find-clause clauses tag)
    (for/first ([clause (in-list clauses)]
                #:when (let ([items (syntax->list clause)])
                         (and items
                              (pair? items)
                              (eq? (syntax-e (car items)) tag))))
      clause))

  (define (clause-body clause)
    (if clause (cdr (syntax->list clause)) '()))

  (define (remove-clause-tags clauses tags)
    (filter
     (lambda (clause)
       (define items (syntax->list clause))
       (not (and items
                 (pair? items)
                 (memq (syntax-e (car items)) tags))))
     clauses))

  (define (one-value who clause)
    (define body (clause-body clause))
    (unless (= (length body) 1)
      (raise-syntax-error who "expected exactly one value" clause))
    (car body))

  (define (string-syntax ctx value)
    (datum->syntax ctx value))

  (define (string-list-syntax ctx values)
    (map (lambda (value) (string-syntax ctx value)) values))

  (define (dict-preset ctx dict-stx)
    (case (syntax-e dict-stx)
      [(luna_pinyin)
       (values (datum->syntax ctx 'luna_pinyin)
               (string-syntax ctx "小鶴雙拼")
               (string-syntax ctx "0.18.custom")
               (string-syntax ctx "朙月拼音＋小鶴雙拼方案。")
               (string-syntax ctx "朙月拼音＋小鶴雙拼方案。\n精簡版，適合移動端匯入")
               (string-list-syntax ctx '("flypy.yaml" "luna_pinyin.dict.yaml"))
               '())]
      [(ice rime_ice)
       (values (datum->syntax ctx 'rime_ice)
               (string-syntax ctx "霧凇")
               (string-syntax ctx "0.1")
               (string-syntax ctx "朙月拼音＋小鶴雙拼方案，使用 rime-ice 詞庫。")
               (string-syntax ctx "朙月拼音＋小鶴雙拼方案。\n使用 rime-ice 詞庫，精簡版，適合移動端匯入")
               (string-list-syntax ctx '("rime_ice.dict.yaml"))
               (string-list-syntax ctx '("rime_ice_dicts")))]
      [else
       (raise-syntax-error 'dictionary
                           "unknown Flypy dictionary preset; expected luna_pinyin or ice"
                           dict-stx)]))

  (define (variant-clause? clause)
    (define items (syntax->list clause))
    (and items
         (pair? items)
         (eq? (syntax-e (car items)) 'variant)))

  (define (variant-id clause)
    (define body (cdr (syntax->list clause)))
    (unless (and (pair? body) (identifier? (car body)))
      (raise-syntax-error 'variant "expected variant schema id" clause))
    (car body))

  (define (variant-body clause)
    (define body (cdr (syntax->list clause)))
    (unless (and (pair? body) (identifier? (car body)))
      (raise-syntax-error 'variant "expected variant schema id" clause))
    (cdr body))

  (define (prefixed-id ctx schema-id suffix)
    (format-id ctx "~a-~a" schema-id suffix)))

(define-syntax (flypy-family stx)
  (syntax-parse stx
    [(_ clause ...)
     (define clauses (syntax->list #'(clause ...)))
     (define variant-clauses (filter variant-clause? clauses))
     (define schema-ids (cons #'flypy (map variant-id variant-clauses)))
     (define schema-bodies
       (cons (filter (lambda (clause) (not (variant-clause? clause))) clauses)
             (map variant-body variant-clauses)))
     (define schema-name-stxs
       (map (lambda (schema-id)
              (datum->syntax stx (symbol->string (syntax-e schema-id))))
            schema-ids))
     (define config-file-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "config-files")) schema-ids))
     (define schema-artifacts-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "schema-artifacts")) schema-ids))
     (define keyboard-layouts-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "keyboard-layouts")) schema-ids))
     (define keyboard-layout-defs-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "keyboard-layout-defs")) schema-ids))
     (define mobile-only-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "mobile-only?")) schema-ids))
     (define mobile-skins-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "mobile-skins")) schema-ids))
     (define mobile-skin-defs-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "mobile-skin-defs")) schema-ids))
     (define schema-deps-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "schema-deps")) schema-ids))
     (define static-files-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "static-dep-files")) schema-ids))
     (define static-dirs-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "static-dep-dirs")) schema-ids))
     (define chinese-name-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "chinese-name")) schema-ids))
     (define schema-summary-ids
       (map (lambda (schema-id) (prefixed-id stx schema-id "schema-summary")) schema-ids))
     (define schema-config-entries
       (append-map list schema-name-stxs config-file-ids))
     (define schema-meta-entries
       (for/list ([schema-name (in-list schema-name-stxs)]
                  [schema-artifacts-id (in-list schema-artifacts-ids)]
                  [keyboard-layouts-id (in-list keyboard-layouts-ids)]
                  [keyboard-layout-defs-id (in-list keyboard-layout-defs-ids)]
                  [mobile-only-id (in-list mobile-only-ids)]
                  [mobile-skins-id (in-list mobile-skins-ids)]
                  [mobile-skin-defs-id (in-list mobile-skin-defs-ids)]
                  [schema-deps-id (in-list schema-deps-ids)]
                  [static-files-id (in-list static-files-ids)]
                  [static-dirs-id (in-list static-dirs-ids)]
                  [chinese-name-id (in-list chinese-name-ids)]
                  [schema-summary-id (in-list schema-summary-ids)])
         #`(cons #,schema-name
                 (hash 'schema-artifacts #,schema-artifacts-id
                       'keyboard-layouts #,keyboard-layouts-id
                       'keyboard-layout-defs #,keyboard-layout-defs-id
                       'mobile-only? (not (member "rime" #,schema-artifacts-id))
                       'mobile-skins #,keyboard-layouts-id
                       'mobile-skin-defs #,keyboard-layout-defs-id
                       'schema-deps #,schema-deps-id
                       'static-dep-files #,static-files-id
                       'static-dep-dirs #,static-dirs-id
                       'chinese-name #,chinese-name-id
                       'schema-summary #,schema-summary-id))))
     (define schema-requires
       (for/list ([schema-id (in-list schema-ids)]
                  [config-files-id (in-list config-file-ids)]
                  [schema-artifacts-id (in-list schema-artifacts-ids)]
                  [keyboard-layouts-id (in-list keyboard-layouts-ids)]
                  [keyboard-layout-defs-id (in-list keyboard-layout-defs-ids)]
                  [mobile-only-id (in-list mobile-only-ids)]
                  [mobile-skins-id (in-list mobile-skins-ids)]
                  [mobile-skin-defs-id (in-list mobile-skin-defs-ids)]
                  [schema-deps-id (in-list schema-deps-ids)]
                  [static-files-id (in-list static-files-ids)]
                  [static-dirs-id (in-list static-dirs-ids)]
                  [chinese-name-id (in-list chinese-name-ids)]
                  [schema-summary-id (in-list schema-summary-ids)])
         #`(require (rename-in (submod "." #,schema-id)
                               [config-files #,config-files-id]
                               [schema-artifacts #,schema-artifacts-id]
                               [keyboard-layouts #,keyboard-layouts-id]
                               [keyboard-layout-defs #,keyboard-layout-defs-id]
                               [mobile-only? #,mobile-only-id]
                               [mobile-skins #,mobile-skins-id]
                               [mobile-skin-defs #,mobile-skin-defs-id]
                               [schema-deps #,schema-deps-id]
                               [static-dep-files #,static-files-id]
                               [static-dep-dirs #,static-dirs-id]
                               [chinese-name #,chinese-name-id]
                               [schema-summary #,schema-summary-id]))))
     (define lang-path (datum->syntax stx "lib/lang.rkt"))
     (define self-path (datum->syntax stx "families/flypy.rkt"))
     (with-syntax ([(schema-id ...) schema-ids]
                   [flypy-schema (datum->syntax #f 'flypy-schema)]
                   [((schema-clause ...) ...) schema-bodies]
                   [(schema-config-entry ...) schema-config-entries]
                   [(schema-meta-entry ...) schema-meta-entries]
                   [(schema-require ...) schema-requires]
                   [(config-files-id ...) config-file-ids]
                   [base-schema-artifacts (car schema-artifacts-ids)]
                   [base-keyboard-layouts (car keyboard-layouts-ids)]
                   [base-keyboard-layout-defs (car keyboard-layout-defs-ids)]
                   [base-schema-deps (car schema-deps-ids)]
                   [base-static-dep-files (car static-files-ids)]
                   [base-static-dep-dirs (car static-dirs-ids)]
                   [base-chinese-name (car chinese-name-ids)]
                   [base-schema-summary (car schema-summary-ids)])
       #`(begin
           (require racket/hash)

           (module schema-id racket/base
             (require #,lang-path
                      #,self-path)
             (flypy-schema schema-id schema-clause ...))
           ...

           schema-require
           ...

           (define schema-artifacts base-schema-artifacts)
           (define keyboard-layouts base-keyboard-layouts)
           (define keyboard-layout-defs base-keyboard-layout-defs)
           (define mobile-only? (not (member "rime" schema-artifacts)))
           (define mobile-skins keyboard-layouts)
           (define mobile-skin-defs keyboard-layout-defs)
           (define schema-deps base-schema-deps)
           (define static-dep-files base-static-dep-files)
           (define static-dep-dirs base-static-dep-dirs)
           (define chinese-name base-chinese-name)
           (define schema-summary base-schema-summary)

           (define schema-config-files
             (hash schema-config-entry ...))

           (define schema-meta
             (make-immutable-hash (list schema-meta-entry ...)))

           (define config-files
             (hash-union config-files-id ...))

           (provide config-files
                    schema-config-files
                    schema-meta
                    schema-artifacts
                    keyboard-layouts
                    keyboard-layout-defs
                    mobile-only?
                    mobile-skins
                    mobile-skin-defs
                    schema-deps
                    static-dep-files
                    static-dep-dirs
                    chinese-name
                    schema-summary)))]))

(define-syntax (flypy-schema stx)
  (syntax-parse stx
    [(_ schema-id:id clause ...)
     (define clauses (syntax->list #'(clause ...)))
     (define name-cl (find-clause clauses 'name))
     (define dict-cl (find-clause clauses 'dictionary))
     (define version-cl (find-clause clauses 'version))
     (define description-cl (find-clause clauses 'description))
     (define custom-description-cl (find-clause clauses 'custom-description))
     (define static-files-cl (find-clause clauses 'static-files))
     (define static-dirs-cl (find-clause clauses 'static-dirs))
     (unless dict-cl (raise-syntax-error 'flypy-schema "missing (dictionary ...)" stx))
     (define dict-stx (one-value 'dictionary dict-cl))
     (define-values (rime-dict-stx
                     default-name
                     default-version
                     default-description
                     default-custom-description
                     default-static-files
                     default-static-dirs)
       (dict-preset stx dict-stx))
     (define extra-clauses
       (remove-clause-tags
        clauses
        '(name dictionary version description custom-description static-files static-dirs)))
     #`(rime-schema schema-id
         (name #,(if name-cl (one-value 'name name-cl) default-name))
         (deps cangjie6)
         (static-files #,@(if static-files-cl
                              (clause-body static-files-cl)
                              default-static-files))
         #,@(if (or static-dirs-cl (pair? default-static-dirs))
                (list #`(static-dirs #,@(if static-dirs-cl
                                             (clause-body static-dirs-cl)
                                             default-static-dirs)))
                '())
         (schema
          (version #,(if version-cl (one-value 'version version-cl) default-version))
          (authors
           "double pinyin layout by 鶴"
           "Rime schema by 佛振 <chen.sst@gmail.com>")
          (description #,(if description-cl
                             (one-value 'description description-cl)
                             default-description))
          (switches
           (switch 'ascii_mode #:reset 0 #:states '("鶴" "A"))
           (switch 'simplification #:states '("漢字" "汉字"))
           (switch 'full_shape #:states '("半角" "全角"))
           (switch 'ascii_punct #:states '("。，" "．，")))
          (engine
           #:translators '(punct_translator reverse_lookup_translator script_translator))
          (speller
           #:alphabet "zyxwvutsrqponmlkjihgfedcba"
           #:delimiter " '"
           #:algebra
           '("erase/^xx$/"
             "derive/^([jqxy])u$/$1v/"
             "derive/^([aoe])([ioun])$/$1$1$2/"
             "xform/^([aoe])(ng)?$/$1$1$2/"
             "xform/iu$/Q/"
             "xform/(.)ei$/$1W/"
             "xform/uan$/R/"
             "xform/[uv]e$/T/"
             "xform/un$/Y/"
             "xform/^sh/U/"
             "xform/^ch/I/"
             "xform/^zh/V/"
             "xform/uo$/O/"
             "xform/ie$/P/"
             "xform/i?ong$/S/"
             "xform/ing$|uai$/K/"
             "xform/(.)ai$/$1D/"
             "xform/(.)en$/$1F/"
             "xform/(.)eng$/$1G/"
             "xform/[iu]ang$/L/"
             "xform/(.)ang$/$1H/"
             "xform/ian$/M/"
             "xform/(.)an$/$1J/"
             "xform/(.)ou$/$1Z/"
             "xform/[iu]a$/X/"
             "xform/iao$/N/"
             "xform/(.)ao$/$1C/"
             "xform/ui$/V/"
             "xform/in$/B/"
             "xform/([A-Z])/$1/"
             "xlit/QWRTYUIOPSDFGHJKLZXCVBNM/qwrtyuiopsdfghjklzxcvbnm/"))
          (translator
           #:dictionary '#,rime-dict-stx
           #:prism 'schema-id
           #:preedit-format (include-ref "flypy:/flypy"))
          (reverse-lookup
           #:dictionary 'cangjie6
           #:prefix "`"
           #:suffix "'"
           #:tips "〔蒼頡〕"
           #:preedit-format
           '("xlit|abcdefghijklmnopqrstuvwxyz|日月金木水火土的戈十大中一弓人心手口尸廿山女田止卜片|")
           #:comment-format
           '("xlit|abcdefghijklmnopqrstuvwxyz|日月金木水火土的戈十大中一弓人心手口尸廿山女田止卜片|"))
          (preset-section 'punctuator)
          (preset-section 'key_binder)
          (recognizer
           #:patterns
           (list (pattern 'reverse_lookup "`[a-z]*'?$"))))
         (custom #,(format "~a.custom.yaml" (syntax-e #'schema-id))
           (includes yuanshu_common_patch yuanshu_reverse_lookup_patch)
           (version #,(if version-cl (one-value 'version version-cl) default-version))
           (description #,(if custom-description-cl
                              (one-value 'custom-description custom-description-cl)
                              default-custom-description)))
         #,@extra-clauses)]))
