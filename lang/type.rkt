#lang racket/base

(require racket/list)

(provide (struct-out input-method-dimension)
         (struct-out input-method-keyboard)
         (struct-out schema-declaration)
         define-type-catalog
         schema
         method
         keyboard)

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

(define-syntax-rule (define-type-catalog name entry ...)
  (define name (list entry ...)))
