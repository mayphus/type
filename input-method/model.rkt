#lang racket/base

(provide (struct-out schema-definition)
         input-method-definition?
         input-method-definition-id
         input-method-definition-source-id
         input-method-definition-kind
         input-method-definition-catalog
         input-method-definition-artifacts
         input-method-definition-deps
         input-method-definition-static-files
         input-method-definition-static-dirs
         input-method-definition-names
         input-method-definition-descriptions
         input-method-definition-keyboard-layouts
         make-schema-definition
         localized-schema-value)

(struct schema-definition
  (id
   source-id
   kind
   catalog
   artifacts
   deps
   static-files
   static-dirs
   names
   descriptions
   keyboard-layouts)
  #:transparent)

(define (make-schema-definition #:id id
                                #:source-id [source-id id]
                                #:kind [kind 'static]
                                #:catalog [catalog "other"]
                                #:artifacts [artifacts '("rime" "yuanshu")]
                                #:deps [deps '()]
                                #:static-files [static-files '()]
                                #:static-dirs [static-dirs '()]
                                #:names [names #f]
                                #:descriptions [descriptions #f]
                                #:keyboard-layouts [keyboard-layouts '()])
  (schema-definition id
                     source-id
                     kind
                     catalog
                     artifacts
                     deps
                     static-files
                     static-dirs
                     names
                     descriptions
                     keyboard-layouts))

(define input-method-definition? schema-definition?)
(define input-method-definition-id schema-definition-id)
(define input-method-definition-source-id schema-definition-source-id)
(define input-method-definition-kind schema-definition-kind)
(define input-method-definition-catalog schema-definition-catalog)
(define input-method-definition-artifacts schema-definition-artifacts)
(define input-method-definition-deps schema-definition-deps)
(define input-method-definition-static-files schema-definition-static-files)
(define input-method-definition-static-dirs schema-definition-static-dirs)
(define input-method-definition-names schema-definition-names)
(define input-method-definition-descriptions schema-definition-descriptions)
(define input-method-definition-keyboard-layouts schema-definition-keyboard-layouts)

(define (localized-schema-value values locale [default #f])
  (cond
    [(hash? values)
     (hash-ref values locale
               (lambda ()
                 (hash-ref values 'en
                           (lambda ()
                             (hash-ref values 'zh-Hant default)))))]
    [else values]))
