#lang racket/base

(require racket/list
         "../input-method/calculate.rkt")

(provide rime-schema-ids
         generated-schema-ids
         generated-package-ids
         generated-custom-ids
         generated-config-ids
         extra-schema-ids-with-mobile
         rime-schema-source-id
         rime-schema-config-id
         rime-schema-deps
         rime-schema-extra-files
         rime-schema-extra-dirs
         rime-schema-keyboard-layouts
         rime-schema-artifacts)

;; Rime remains an adapter surface. The durable source of truth is the
;; input-method recipe catalog, which also describes Yuanshu layouts and skins.

(define rime-entries input-method-recipes)

(define rime-entry-by-id
  (for/hash ([definition (in-list rime-entries)])
    (values (input-method-recipe-id definition) definition)))

(define (rime-ref id)
  (hash-ref rime-entry-by-id id #f))

(define (rime-schema-ids)
  (map input-method-recipe-id rime-entries))

(define (filter-rime-ids pred?)
  (for/list ([definition (in-list rime-entries)]
             #:when (pred? definition))
    (input-method-recipe-id definition)))

(define generated-schema-ids
  (filter-rime-ids input-method-recipe-rime-generated?))

(define generated-package-ids
  (filter-rime-ids input-method-recipe-rime-package?))

(define generated-custom-ids
  (filter-rime-ids input-method-recipe-rime-custom?))

(define generated-config-ids
  (remove-duplicates (append generated-schema-ids
                             generated-package-ids
                             generated-custom-ids)))

(define extra-schema-ids-with-mobile
  '("bopomofo"))

(define (rime-schema-source-id schema)
  (define definition (rime-ref schema))
  (if definition
      (input-method-recipe-rime-source-id definition)
      schema))

(define (rime-schema-config-id schema)
  (define definition (rime-ref schema))
  (if definition
      (input-method-recipe-rime-config-id definition)
      (rime-schema-source-id schema)))

(define (rime-schema-deps schema)
  (define definition (rime-ref schema))
  (if definition
      (input-method-recipe-rime-deps definition)
      '()))

(define (rime-schema-extra-files schema)
  (define definition (rime-ref schema))
  (if definition
      (input-method-recipe-rime-extra-files definition)
      '()))

(define (rime-schema-extra-dirs schema)
  (define definition (rime-ref schema))
  (if definition
      (input-method-recipe-rime-extra-dirs definition)
      '()))

(define (rime-schema-keyboard-layouts schema)
  (define definition (rime-ref schema))
  (if definition
      (input-method-recipe-keyboard-layouts definition)
      '()))

(define (rime-schema-artifacts schema)
  (define definition (rime-ref schema))
  (if definition
      (input-method-recipe-rime-artifacts definition)
      '("rime" "yuanshu")))
