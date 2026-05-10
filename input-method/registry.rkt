#lang racket/base

(require "schema.rkt"
         "model.rkt"
         "../rime/registry.rkt")

(provide generated-schema-ids
         generated-custom-ids
         generated-config-ids
         schema-entry-ids
         extra-schema-ids-with-mobile
         schema-source-id
         schema-config-id
         static-schema-deps
         static-schema-extra-files
         static-schema-extra-dirs
         static-schema-keyboard-layouts
         schema-slug
         static-schema-name
         static-schema-description
         static-schema-artifacts
         schema-display-names
         schema-display-descriptions
         input-method-id?
         schema-category-order
         schema-id->category-id
         schema-category-label
         schema-category-summary)

(define (schema-ref schema)
  (schema-entry-ref schema #f))

(define (schema-source-id schema)
  (rime-schema-source-id schema))

(define (schema-config-id schema)
  (rime-schema-config-id schema))

(define (schema-display-names schema)
  (define definition (schema-ref schema))
  (and definition (schema-entry-names definition)))

(define (schema-display-descriptions schema)
  (define definition (schema-ref schema))
  (and definition (schema-entry-descriptions definition)))

(define (input-method-id? id)
  (and (member id (input-method-schema-entry-ids)) #t))

(define (static-schema-deps schema)
  (rime-schema-deps schema))

(define (static-schema-extra-files schema)
  (rime-schema-extra-files schema))

(define (static-schema-extra-dirs schema)
  (rime-schema-extra-dirs schema))

(define (static-schema-keyboard-layouts schema)
  (rime-schema-keyboard-layouts schema))

(define (schema-slug schema)
  (define definition (schema-ref schema))
  (if definition
      (schema-entry-slug definition)
      schema))

(define (static-schema-name schema)
  (localized-schema-value (schema-display-names schema) 'zh-Hant))

(define (static-schema-description schema)
  (localized-schema-value (schema-display-descriptions schema) 'en))

(define (static-schema-artifacts schema)
  (rime-schema-artifacts schema))

(define (schema-id->category-id id)
  (define definition (schema-ref id))
  (if definition
      (schema-entry-category definition)
      "other"))
