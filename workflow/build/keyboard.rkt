#lang racket/base

(require racket/format
         racket/list
         racket/set
         "../../keyboard/registry.rkt"
         "../../rime/registry.rkt"
         "paths.rkt")

(provide keyboard-layout-module?
         keyboard-layout-module-ref
         skin-module-ref
         schema-keyboard-layout-module-path
         schema-mobile-skin-module-path
         list-keyboard-layout-items
         list-mobile-skin-items)

(struct keyboard-layout-module (schema layout body) #:transparent)

(define keyboard-layout-module-namespace (make-base-namespace))
(define declared-keyboard-layout-modules (mutable-set))

(define (keyboard-layout-runtime-module-name schema layout)
  (string->symbol (format "input-foundry-keyboard-layout-~a-~a" schema layout)))

(define (declare-keyboard-layout-module! mod ns)
  (define name
    (keyboard-layout-runtime-module-name
     (keyboard-layout-module-schema mod)
     (keyboard-layout-module-layout mod)))
  (unless (and (eq? ns keyboard-layout-module-namespace)
               (set-member? declared-keyboard-layout-modules name))
    (parameterize ([current-namespace ns])
      (eval `(module ,name
               (file ,(path->string yuanshu-skin-lang-path))
               (yuanshu-skin ,(string->symbol (keyboard-layout-module-layout mod))
                 (triggers ,(string->symbol (keyboard-layout-module-schema mod)))
                 ,@(keyboard-layout-module-body mod)))))
    (when (eq? ns keyboard-layout-module-namespace)
      (set-add! declared-keyboard-layout-modules name))))

(define (keyboard-layout-module-ref mod export-sym [default-thunk #f] #:fresh? [fresh? #f])
  (define ns (if fresh? (make-base-namespace) keyboard-layout-module-namespace))
  (declare-keyboard-layout-module! mod ns)
  (parameterize ([current-namespace ns])
    (if default-thunk
        (dynamic-require
         `',(keyboard-layout-runtime-module-name
             (keyboard-layout-module-schema mod)
             (keyboard-layout-module-layout mod))
         export-sym
         default-thunk)
        (dynamic-require
         `',(keyboard-layout-runtime-module-name
             (keyboard-layout-module-schema mod)
             (keyboard-layout-module-layout mod))
         export-sym))))

(define skin-module-ref keyboard-layout-module-ref)

(define (schema-module-path schema)
  (build-path rime-source-dir (string-append (rime-schema-source-id schema) ".rkt")))

(define (schema-module-ref schema prop [default #f])
  (define source (rime-schema-source-id schema))
  (define rkt (schema-module-path schema))
  (if (file-exists? rkt)
      (if (equal? source schema)
          (dynamic-require rkt prop (lambda () default))
          (let ([meta (dynamic-require rkt 'schema-meta (lambda () #f))])
            (if (hash? meta)
                (hash-ref (hash-ref meta schema
                                    (hash-ref meta (rime-schema-config-id schema) (hash)))
                          prop
                          (lambda ()
                            (dynamic-require rkt prop (lambda () default))))
                (dynamic-require rkt prop (lambda () default)))))
      default))

(define (read-schema-keyboard-layouts schema)
  (define layouts (schema-module-ref schema 'keyboard-layouts
                                     (schema-module-ref schema 'mobile-skins
                                                        (rime-schema-keyboard-layouts schema))))
  (cond
    [(not layouts) '()]
    [(list? layouts) layouts]
    [else (list layouts)]))

(define (schema-keyboard-layout-body schema layout)
  (define layout-defs (schema-module-ref schema 'keyboard-layout-defs
                                         (schema-module-ref schema 'mobile-skin-defs '())))
  (cond
    [(assoc layout layout-defs) => cdr]
    [(keyboard-layout-definition-ref layout) => values]
    [else #f]))

(define (schema-keyboard-layout-module schema layout body)
  (keyboard-layout-module schema layout body))

(define (schema-keyboard-layout-module-path layout schemas)
  (define search-schemas
    (remove-duplicates (append schemas generated-config-ids extra-schema-ids-with-mobile)))
  (for/or ([schema (in-list search-schemas)])
    (define body (schema-keyboard-layout-body schema layout))
    (and body (schema-keyboard-layout-module schema layout body))))

(define (schema-mobile-skin-module-path skin schemas)
  (schema-keyboard-layout-module-path skin schemas))

(define (list-keyboard-layout-items schemas)
  (define search-schemas
    (remove-duplicates (append schemas generated-config-ids extra-schema-ids-with-mobile)))
  (for*/list ([schema (in-list search-schemas)]
              [layout (in-list (read-schema-keyboard-layouts schema))]
              #:do [(define body (schema-keyboard-layout-body schema layout))]
              #:when body)
    (list schema layout (schema-keyboard-layout-module schema layout body))))

(define list-mobile-skin-items list-keyboard-layout-items)
