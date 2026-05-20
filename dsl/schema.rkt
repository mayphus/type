#lang racket/base

(require racket/string
         "../input-method/model.rkt")

(provide define-schema
         entry)

(define-syntax-rule (define-schema id option ...)
  (begin
    (provide schema-entry)
    (define schema-entry
      (entry id option ...))))

(define (entry id
               #:slug [slug (string-replace id "_" "-")]
               #:category [category "other"]
               #:rule [rule category]
               #:deps [deps '()]
               #:en-name en-name
               #:zh-name zh-name
               #:en-description en-description
               #:zh-description zh-description)
  (make-schema-entry
   #:id id
   #:slug slug
   #:category category
   #:rule rule
   #:deps deps
   #:names (hash 'en en-name 'zh-Hant zh-name)
   #:descriptions (hash 'en en-description 'zh-Hant zh-description)))
