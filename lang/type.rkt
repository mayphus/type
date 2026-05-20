#lang racket/base

(require racket/list
         racket/string)

(provide (struct-out input-method-dimension)
         (struct-out input-method-keyboard)
         (struct-out schema-declaration)
         (struct-out rime-config)
         (struct-out layout-declaration)
         (struct-out family-layout-template)
         (struct-out support-schema-declaration)
         define-input-methods
         schema
         method
         keyboard
         input-method
         input-family
         family-layout
         support-schema
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

(struct family-layout-template
  (suffix
   keyboard-id
   generated-skin-id
   skin-suffix
   placement
   rime-source-id
   rime-source-suffix)
  #:transparent)

(struct support-schema-declaration
  (id
   source-id
   config-id
   generated?
   package?
   custom?
   deps
   extra-files
   extra-dirs
   artifacts)
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

(define (target-id value)
  (cond
    [(not value) #f]
    [(string? value) (string-replace value "-" "_")]
    [else value]))

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
  (rime-config (target-id source-id)
               (target-id config-id)
               generated?
               package?
               custom?
               deps
               extra-files
               extra-dirs
               artifacts
               deep-config))

(define (make-layout recipe-id
                     #:keyboard [keyboard-id 'standard-26]
                     #:skin [skin-id recipe-id]
                     #:placement [placement 'standard-center]
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
                      (target-id skin-id)
                      placement
                      (localized-value name)
                      (localized-value description)
                      (target-id rime-source-id)
                      (target-id rime-config-id)
                      rime-generated?
                      rime-package?
                      rime-custom?
                      rime-deps
                      rime-extra-files
                      rime-extra-dirs
                      rime-artifacts))

(define (make-family-layout suffix
                            #:keyboard keyboard-id
                            #:generated-skin [generated-skin-id #f]
                            #:skin-suffix [skin-suffix suffix]
                            #:placement [placement 'standard-center]
                            #:rime-source [rime-source-id #f]
                            #:rime-source-suffix [rime-source-suffix #f])
  (family-layout-template suffix
                          keyboard-id
                          (target-id generated-skin-id)
                          skin-suffix
                          placement
                          (target-id rime-source-id)
                          rime-source-suffix))

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

(define (make-support-schema id
                             #:source [source-id id]
                             #:config [config-id #f]
                             #:category [category "other"]
                             #:rule [rule category]
                             #:deps [schema-deps '()]
                             #:slug [slug id]
                             #:name [name #f]
                             #:description [description #f]
                             #:rime-deps [rime-deps '()]
                             #:extra-files [extra-files '()]
                             #:extra-dirs [extra-dirs '()]
                             #:artifacts [artifacts '("rime" "yuanshu")]
                             #:generated? [generated? #f]
                             #:package? [package? #f]
                             #:custom? [custom? #f])
  (list
   (schema id
           #:slug slug
           #:category category
           #:rule rule
           #:deps schema-deps
           #:name name
           #:description description)
   (support-schema-declaration id
                               (target-id source-id)
                               (target-id config-id)
                               generated?
                               package?
                               custom?
                               rime-deps
                               extra-files
                               extra-dirs
                               artifacts)))

(define (family-schema item category rule)
  (if (schema-declaration? item)
      (let* ([current-category (schema-declaration-category item)]
             [next-category (if (and category (equal? current-category "other"))
                                category
                                current-category)]
             [next-rule (cond
                          [rule rule]
                          [(and category (equal? (schema-declaration-rule item) "other"))
                           next-category]
                          [else (schema-declaration-rule item)])])
        (schema-declaration (schema-declaration-id item)
                            next-category
                            next-rule
                            (schema-declaration-deps item)
                            (schema-declaration-slug item)
                            (schema-declaration-names item)
                            (schema-declaration-descriptions item)))
      item))

(define (family-keyboard item skin placement rime-deps rime-extra-files)
  (define current-skin (input-method-keyboard-layout-id item))
  (input-method-keyboard (input-method-keyboard-recipe-id item)
                         (input-method-keyboard-keyboard-id item)
                         (if (and skin
                                  (equal? current-skin
                                          (target-id (input-method-keyboard-recipe-id item))))
                             (target-id skin)
                             current-skin)
                         (if (and placement
                                  (eq? (input-method-keyboard-placement item) 'standard-center))
                             placement
                             (input-method-keyboard-placement item))
                         (input-method-keyboard-names item)
                         (input-method-keyboard-descriptions item)
                         (input-method-keyboard-rime-source-id item)
                         (input-method-keyboard-rime-config-id item)
                         (input-method-keyboard-rime-generated? item)
                         (input-method-keyboard-rime-package? item)
                         (input-method-keyboard-rime-custom? item)
                         (if (and rime-deps (null? (input-method-keyboard-rime-deps item)))
                             rime-deps
                             (input-method-keyboard-rime-deps item))
                         (if (and rime-extra-files
                                  (null? (input-method-keyboard-rime-extra-files item)))
                             rime-extra-files
                             (input-method-keyboard-rime-extra-files item))
                         (input-method-keyboard-rime-extra-dirs item)
                         (input-method-keyboard-rime-artifacts item)))

(define (append-target-suffix value suffix)
  (and value suffix (string-append value (target-id suffix))))

(define (templated-family-keyboard base template)
  (define next-source
    (cond
      [(and (input-method-keyboard-rime-generated? base)
            (family-layout-template-rime-source-id template))
       (family-layout-template-rime-source-id template)]
      [(and (input-method-keyboard-rime-generated? base)
            (family-layout-template-rime-source-suffix template))
       (append-target-suffix (input-method-keyboard-rime-source-id base)
                             (family-layout-template-rime-source-suffix template))]
      [else (input-method-keyboard-rime-source-id base)]))
  (input-method-keyboard
   (string-append (input-method-keyboard-recipe-id base)
                  (family-layout-template-suffix template))
   (family-layout-template-keyboard-id template)
   (if (and (input-method-keyboard-rime-generated? base)
            (family-layout-template-generated-skin-id template))
       (family-layout-template-generated-skin-id template)
       (append-target-suffix (input-method-keyboard-layout-id base)
                             (family-layout-template-skin-suffix template)))
   (family-layout-template-placement template)
   #f
   #f
   next-source
   (if (equal? next-source (input-method-keyboard-rime-source-id base))
       (input-method-keyboard-rime-config-id base)
       #f)
   (input-method-keyboard-rime-generated? base)
   (input-method-keyboard-rime-package? base)
   (input-method-keyboard-rime-custom? base)
   (input-method-keyboard-rime-deps base)
   (input-method-keyboard-rime-extra-files base)
   (input-method-keyboard-rime-extra-dirs base)
   (input-method-keyboard-rime-artifacts base)))

(define (family-template-keyboards method-id keyboards templates)
  (define base
    (for/first ([item (in-list keyboards)]
                #:when (equal? (input-method-keyboard-recipe-id item) method-id))
      item))
  (if base
      (append keyboards
              (map (lambda (template) (templated-family-keyboard base template))
                   templates))
      keyboards))

(define (family-method item method-schema keymap legends skin placement rime-deps rime-extra-files layout-templates)
  (if (input-method-dimension? item)
      (let* ([method-id (input-method-dimension-id item)]
             [keyboards
              (map (lambda (keyboard)
                     (family-keyboard keyboard skin placement rime-deps rime-extra-files))
                   (input-method-dimension-keyboards item))])
        (input-method-dimension
         method-id
         (if (and method-schema
                  (equal? (input-method-dimension-schema item)
                          method-id))
             method-schema
             (input-method-dimension-schema item))
         (if (and keymap
                  (equal? (input-method-dimension-keymap item)
                          method-id))
             keymap
             (input-method-dimension-keymap item))
         (if (and legends (null? (input-method-dimension-legends item)))
             legends
             (input-method-dimension-legends item))
         (family-template-keyboards method-id keyboards layout-templates)))
      item))

(define (family-entry entry category rule method-schema keymap legends skin placement rime-deps rime-extra-files layout-templates)
  (map (lambda (item)
         (family-method (family-schema item category rule)
                        method-schema
                        keymap
                        legends
                        skin
                        placement
                        rime-deps
                        rime-extra-files
                        layout-templates))
       (catalog-entry->list entry)))

(define (make-input-family #:category [category #f]
                           #:rule [rule #f]
                           #:method-schema [method-schema #f]
                           #:keymap [keymap #f]
                           #:legends [legends #f]
                           #:skin [skin #f]
                           #:placement [placement #f]
                           #:rime-deps [rime-deps #f]
                           #:rime-extra-files [rime-extra-files #f]
                           . clauses)
  (define layout-templates (filter family-layout-template? clauses))
  (define entries (filter (lambda (clause) (not (family-layout-template? clause))) clauses))
  (append-map (lambda (entry)
                (family-entry entry
                              category
                              rule
                              method-schema
                              keymap
                              legends
                              skin
                              placement
                              rime-deps
                              rime-extra-files
                              layout-templates))
              entries))

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

(define-syntax-rule (family-layout arg ...)
  (make-family-layout arg ...))

(define-syntax-rule (input-method arg ...)
  (make-input-method arg ...))

(define-syntax-rule (input-family arg ...)
  (make-input-family arg ...))

(define-syntax-rule (support-schema arg ...)
  (make-support-schema arg ...))

(define (catalog-entry->list entry)
  (if (list? entry) entry (list entry)))

(define-syntax-rule (define-input-methods name entry ...)
  (define name (append-map catalog-entry->list (list entry ...))))
