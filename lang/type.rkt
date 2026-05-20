#lang racket/base

(require racket/list)

(provide (struct-out input-method-dimension)
         (struct-out input-method-keyboard)
         (struct-out schema-declaration)
         (struct-out rime-config)
         (struct-out layout-declaration)
         define-input-methods
         define-type-catalog
         schema
         method
         keyboard
         input-method
         rime
         layout)

(struct input-method-keyboard
  (recipe-id
   keyboard-id
   layout-id
   placement
   names
   descriptions
   rime-source-id
   rime-config-id
   rime-generated?
   rime-package?
   rime-custom?
   rime-deps
   rime-extra-files
   rime-extra-dirs
   rime-artifacts)
  #:transparent)

(struct input-method-dimension
  (id
   schema
   keymap
   legends
   keyboards)
  #:transparent)

(struct schema-declaration
  (id
   category
   rule
   deps
   slug
   names
   descriptions)
  #:transparent)

(struct rime-config
  (source-id
   config-id
   generated?
   package?
   custom?
   deps
   extra-files
   extra-dirs
   artifacts
   deep-config)
  #:transparent)

(struct layout-declaration
  (recipe-id
   keyboard-id
   skin-id
   placement
   names
   descriptions
   rime-source-id
   rime-config-id
   rime-generated?
   rime-package?
   rime-custom?
   rime-deps
   rime-extra-files
   rime-extra-dirs
   rime-artifacts)
  #:transparent)

(define (localized en zh)
  (hash 'en en 'zh-Hant zh))

(define (localized-value value)
  (cond
    [(not value) #f]
    [(hash? value) value]
    [(and (list? value) (= (length value) 2))
     (localized (first value) (second value))]
    [else
     (error 'type "expected #f, locale hash, or two-item list, got ~v" value)]))

(define (make-keyboard recipe-id
                       keyboard-id
                       layout-id
                       placement
                       #:name [name #f]
                       #:description [description #f]
                       #:rime-source-id [rime-source-id #f]
                       #:rime-config-id [rime-config-id #f]
                       #:rime-generated? [rime-generated? #f]
                       #:rime-package? [rime-package? #f]
                       #:rime-custom? [rime-custom? #f]
                       #:rime-deps [rime-deps '()]
                       #:rime-extra-files [rime-extra-files '()]
                       #:rime-extra-dirs [rime-extra-dirs '()]
                       #:rime-artifacts [rime-artifacts '("rime" "yuanshu")])
  (define names
    (localized-value name))
  (define descriptions
    (localized-value description))
  (input-method-keyboard recipe-id
                         keyboard-id
                         layout-id
                         placement
                         names
                         descriptions
                         rime-source-id
                         rime-config-id
                         rime-generated?
                         rime-package?
                         rime-custom?
                         rime-deps
                         rime-extra-files
                         rime-extra-dirs
                         rime-artifacts))

(define (make-method id
                     #:schema [schema id]
                     #:keymap [keymap id]
                     #:legends [legends '()]
                     #:keyboards keyboards)
  (input-method-dimension id schema keymap legends keyboards))

(define (make-rime #:source [source-id #f]
                   #:config [config-id #f]
                   #:generated? [generated? #f]
                   #:package? [package? #f]
                   #:custom? [custom? #f]
                   #:deps [deps '()]
                   #:extra-files [extra-files '()]
                   #:extra-dirs [extra-dirs '()]
                   #:artifacts [artifacts '("rime" "yuanshu")]
                   #:deep-config [deep-config #f])
  (rime-config source-id
               config-id
               generated?
               package?
               custom?
               deps
               extra-files
               extra-dirs
               artifacts
               deep-config))

(define (make-layout recipe-id
                     #:keyboard keyboard-id
                     #:skin [skin-id recipe-id]
                     #:placement placement
                     #:name [name #f]
                     #:description [description #f]
                     #:rime-source [rime-source-id #f]
                     #:rime-config [rime-config-id #f]
                     #:rime-generated? [rime-generated? #f]
                     #:rime-package? [rime-package? #f]
                     #:rime-custom? [rime-custom? #f]
                     #:rime-deps [rime-deps #f]
                     #:rime-extra-files [rime-extra-files #f]
                     #:rime-extra-dirs [rime-extra-dirs #f]
                     #:rime-artifacts [rime-artifacts #f])
  (layout-declaration recipe-id
                      keyboard-id
                      skin-id
                      placement
                      (localized-value name)
                      (localized-value description)
                      rime-source-id
                      rime-config-id
                      rime-generated?
                      rime-package?
                      rime-custom?
                      rime-deps
                      rime-extra-files
                      rime-extra-dirs
                      rime-artifacts))

(define (first-rime-config clauses)
  (for/first ([clause (in-list clauses)]
              #:when (rime-config? clause))
    clause))

(define (layout-clauses clauses)
  (filter layout-declaration? clauses))

(define (or* value fallback)
  (if value value fallback))

(define (rime-list value fallback)
  (if value value fallback))

(define (layout->keyboard layout family-rime)
  (keyboard
   (layout-declaration-recipe-id layout)
   (layout-declaration-keyboard-id layout)
   (layout-declaration-skin-id layout)
   (layout-declaration-placement layout)
   #:name (layout-declaration-names layout)
   #:description (layout-declaration-descriptions layout)
   #:rime-source-id (or* (layout-declaration-rime-source-id layout)
                         (and family-rime (rime-config-source-id family-rime)))
   #:rime-config-id (cond
                      [(layout-declaration-rime-config-id layout)]
                      [(layout-declaration-rime-source-id layout) #f]
                      [family-rime (rime-config-config-id family-rime)]
                      [else #f])
   #:rime-generated? (or (layout-declaration-rime-generated? layout)
                         (and family-rime (rime-config-generated? family-rime)))
   #:rime-package? (or (layout-declaration-rime-package? layout)
                       (and family-rime (rime-config-package? family-rime)))
   #:rime-custom? (or (layout-declaration-rime-custom? layout)
                      (and family-rime (rime-config-custom? family-rime)))
   #:rime-deps (rime-list (layout-declaration-rime-deps layout)
                          (if family-rime (rime-config-deps family-rime) '()))
   #:rime-extra-files (rime-list (layout-declaration-rime-extra-files layout)
                                 (if family-rime (rime-config-extra-files family-rime) '()))
   #:rime-extra-dirs (rime-list (layout-declaration-rime-extra-dirs layout)
                                (if family-rime (rime-config-extra-dirs family-rime) '()))
   #:rime-artifacts (rime-list (layout-declaration-rime-artifacts layout)
                               (if family-rime (rime-config-artifacts family-rime) '("rime" "yuanshu")))))

(define (make-input-method id
                           #:schema [schema-id id]
                           #:method-schema [method-schema-id schema-id]
                           #:slug [slug schema-id]
                           #:category [category "other"]
                           #:rule [rule category]
                           #:deps [schema-deps '()]
                           #:name [name #f]
                           #:description [description #f]
                           #:keymap [keymap id]
                           #:legends [legends '()]
                           . clauses)
  (define family-rime (first-rime-config clauses))
  (define layouts (layout-clauses clauses))
  (list
   (schema schema-id
           #:slug slug
           #:category category
           #:rule rule
           #:deps schema-deps
           #:name name
           #:description description)
   (method id
           #:schema method-schema-id
           #:keymap keymap
           #:legends legends
           #:keyboards (map (lambda (item) (layout->keyboard item family-rime))
                            layouts))))

(define (make-schema id
                     #:slug [slug id]
                     #:category [category "other"]
                     #:rule [rule category]
                     #:deps [deps '()]
                     #:name [name #f]
                     #:description [description #f])
  (schema-declaration id
                      category
                      rule
                      deps
                      slug
                      (localized-value name)
                      (localized-value description)))

(define-syntax-rule (schema arg ...)
  (make-schema arg ...))

(define-syntax-rule (keyboard arg ...)
  (make-keyboard arg ...))

(define-syntax-rule (method arg ...)
  (make-method arg ...))

(define-syntax-rule (rime arg ...)
  (make-rime arg ...))

(define-syntax-rule (layout arg ...)
  (make-layout arg ...))

(define-syntax-rule (input-method arg ...)
  (make-input-method arg ...))

(define (catalog-entry->list entry)
  (if (list? entry) entry (list entry)))

(define-syntax-rule (define-type-catalog name entry ...)
  (define name (append-map catalog-entry->list (list entry ...))))

(define-syntax-rule (define-input-methods name entry ...)
  (define-type-catalog name entry ...))
