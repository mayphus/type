#lang racket/base

(provide (struct-out schema-entry)
         input-method-schema-entry?
         input-method-schema-entry-id
         input-method-schema-entry-category
         input-method-schema-entry-rule
         input-method-schema-entry-deps
         input-method-schema-entry-slug
         input-method-schema-entry-names
         input-method-schema-entry-descriptions
         make-schema-entry
         localized-schema-value)

(struct schema-entry
  (id
   category
   rule
   deps
   slug
   names
   descriptions)
  #:transparent)

(define (make-schema-entry #:id id
                            #:category [category "other"]
                            #:rule [rule category]
                            #:deps [deps '()]
                            #:slug [slug id]
                            #:names [names #f]
                            #:descriptions [descriptions #f])
  (schema-entry id
                 category
                 rule
                 deps
                 slug
                 names
                 descriptions))

(define input-method-schema-entry? schema-entry?)
(define input-method-schema-entry-id schema-entry-id)
(define input-method-schema-entry-category schema-entry-category)
(define input-method-schema-entry-rule schema-entry-rule)
(define input-method-schema-entry-deps schema-entry-deps)
(define input-method-schema-entry-slug schema-entry-slug)
(define input-method-schema-entry-names schema-entry-names)
(define input-method-schema-entry-descriptions schema-entry-descriptions)

(define (localized-schema-value values locale [default #f])
  (cond
    [(hash? values)
     (hash-ref values locale
               (lambda ()
                 (hash-ref values 'en
                           (lambda ()
                             (hash-ref values 'zh-Hant default)))))]
    [else values]))
