#lang racket/base

(require racket/list
         racket/string
         "../core/input-methods.rkt"
         "locale.rkt")

(provide method-key
         method-option-schemas
         schema-method-variants
         customizer-method-schema
         selected-customizer-schema
         schema-layout-title)

(define (schema-id schema)
  (hash-ref schema 'id))

(define (schema-slug schema)
  (hash-ref schema 'slug (schema-id schema)))

(define (schema-name locale schema)
  (localized-value (hash-ref schema 'names
                             (hash-ref schema 'name (schema-id schema)))
                   locale
                   (schema-id schema)))

(define (schema-input-method? schema)
  (hash-ref schema 'input-method? #t))

(define (schema-by-id schemas id)
  (for/first ([schema (in-list schemas)]
              #:when (equal? id (schema-id schema)))
    schema))

(define (method-key schema)
  (list (schema-id->category-id (hash-ref schema 'schema-id (schema-id schema)))
        (hash-ref schema 'schema-id (schema-id schema))
        (hash-ref schema 'keymap #f)))

(define (method-option-schemas schemas)
  (define-values (items _seen)
    (for/fold ([items '()]
               [seen '()])
              ([schema (in-list schemas)]
               #:when (schema-input-method? schema))
      (define key (method-key schema))
      (if (member key seen)
          (values items seen)
          (values (cons schema items) (cons key seen)))))
  (reverse items))

(define (schema-method-variants schemas method-schema)
  (filter (lambda (schema)
            (and (schema-input-method? schema)
                 (equal? (method-key schema)
                         (method-key method-schema))))
          schemas))

(define (customizer-method-schema methods selected)
  (for/first ([schema (in-list methods)]
              #:when (equal? (method-key schema) (method-key selected)))
    schema))

(define (schema-layout-note locale schema)
  (define keyboard (hash-ref schema 'keyboard 'standard-26))
  (define en?
    (eq? locale 'en))
  (case keyboard
    [(standard-26) (if en? "Standard 26-Key" "標準 26 鍵")]
    [(compact-9) (if en? "9-Key" "9 鍵")]
    [(compact-14) (if en? "14-Key" "14 鍵")]
    [(shuffle-17) (if en? "Shuffle 17-Key" "亂序 17 鍵")]
    [(compact-18) (if en? "18-Key" "18 鍵")]
    [(standard-zhuyin) (if en? "Standard Zhuyin" "標準注音")]
    [(zhuyin) (if en? "Ortholinear" "正交鍵盤")]
    [else (string-replace (format "~a" keyboard) "-" " ")]))

(define (schema-layout-title locale method-schema schema)
  (format "~a · ~a"
          (schema-name locale (or method-schema schema))
          (schema-layout-note locale schema)))

(define (schema-ref-match? schema ref)
  (or (equal? ref (schema-id schema))
      (equal? ref (schema-slug schema))))

(define (selected-customizer-schema schemas requested-ref)
  (or (and requested-ref
           (for/first ([schema (in-list schemas)]
                       #:when (schema-ref-match? schema requested-ref))
             schema))
      (schema-by-id schemas "double-pinyin-flypy-9")
      (for/first ([schema (in-list schemas)]
                  #:when (schema-input-method? schema))
        schema)))
