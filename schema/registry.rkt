#lang racket/base

(require "catalog.rkt"
         "model.rkt")

(provide generated-schema-ids
         generated-custom-ids
         generated-config-ids
         extra-schema-ids-with-mobile
         schema-source-id
         static-schema-deps
         static-schema-extra-files
         static-schema-extra-dirs
         static-schema-keyboard-layouts
         static-schema-name
         static-schema-description
         static-schema-artifacts
         schema-display-names
         schema-display-descriptions
         schema-catalog-order
         schema-id->catalog-id
         schema-catalog-label
         schema-catalog-summary)

(define (schema-ref schema)
  (schema-definition-ref schema #f))

(define (schema-source-id schema)
  (define definition (schema-ref schema))
  (if definition
      (schema-definition-source-id definition)
      schema))

(define (schema-display-names schema)
  (define definition (schema-ref schema))
  (and definition (schema-definition-names definition)))

(define (schema-display-descriptions schema)
  (define definition (schema-ref schema))
  (and definition (schema-definition-descriptions definition)))

(define (static-schema-deps schema)
  (define definition (schema-ref schema))
  (if definition (schema-definition-deps definition) '()))

(define (static-schema-extra-files schema)
  (define definition (schema-ref schema))
  (if definition (schema-definition-static-files definition) '()))

(define (static-schema-extra-dirs schema)
  (define definition (schema-ref schema))
  (if definition (schema-definition-static-dirs definition) '()))

(define (static-schema-keyboard-layouts schema)
  (define definition (schema-ref schema))
  (if definition (schema-definition-keyboard-layouts definition) '()))

(define (static-schema-name schema)
  (localized-schema-value (schema-display-names schema) 'zh-Hant))

(define (static-schema-description schema)
  (localized-schema-value (schema-display-descriptions schema) 'en))

(define (static-schema-artifacts schema)
  (define definition (schema-ref schema))
  (if definition (schema-definition-artifacts definition) '("rime" "yuanshu")))

(define (schema-id->catalog-id id)
  (define definition (schema-ref id))
  (if definition
      (schema-definition-catalog definition)
      "other"))
