#lang racket/base

(provide (struct-out schema-definition)
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

(define (localized-schema-value values locale [default #f])
  (cond
    [(hash? values)
     (hash-ref values locale
               (lambda ()
                 (hash-ref values 'en
                           (lambda ()
                             (hash-ref values 'zh-Hant default)))))]
    [else values]))
