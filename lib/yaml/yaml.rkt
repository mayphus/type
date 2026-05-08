#lang racket/base

(require racket/format
         racket/string)

(provide ymap
         yseq
         ymap?
         yseq?
         mapping
         sequence
         kv
         yaml->string)

(struct ymap (entries) #:transparent)
(struct yseq (items) #:transparent)

(define (mapping . entries)
  (ymap entries))

(define (sequence . items)
  (yseq items))

(define (kv key value)
  (cons key value))

(define (indent level)
  (make-string (* 2 level) #\space))

(define (safe-plain-string? value)
  (and (positive? (string-length value))
       (regexp-match?
        #px"^[[:alnum:]_./+@|^-][[:alnum:]_ ./+@:'|?^$()*-]*$"
        value)
       (not (regexp-match? #px"^[-?:]|^\\s|\\s$" value))
       (not (regexp-match? #px"^(?:[+-]?[0-9]+(?:\\.[0-9]+)?|[0-9.]+|true|false|null)$" value))
       (not (string-contains? value "#"))
       (not (string-contains? value "`"))
       (not (string-contains? value "["))
       (not (string-contains? value "]"))
       (not (string-contains? value "{"))
       (not (string-contains? value "}"))
       (not (string-contains? value ","))))

(define (quote-string value)
  (string-append
   "\""
   (string-replace
    (string-replace value "\\" "\\\\")
    "\"" "\\\"")
   "\""))

(define (scalar->yaml value)
  (cond
    ((string? value)
     (cond
       ((string-contains? value "\n") #f)
       ((safe-plain-string? value) value)
       (else (quote-string value))))
    ((symbol? value) (symbol->string value))
    ((number? value) (~a value))
    ((boolean? value) (if value "true" "false"))
    (else
     (raise-arguments-error
      'scalar->yaml
      "unsupported scalar value"
      "value" value))))

(define (multiline->yaml level value)
  (string-append
   "|\n"
   (string-join
    (map (lambda (line)
           (string-append (indent (add1 level)) line))
         (string-split value "\n" #:trim? #f))
    "\n")))

(define (render-mapping entries level)
  (string-join
   (map (lambda (entry)
          (render-pair (car entry) (cdr entry) level))
        entries)
   "\n"))

(define (render-pair key value level)
  (cond
    ((ymap? value)
     (define entries (ymap-entries value))
     (if (null? entries)
         (string-append (indent level) key ": {}")
         (string-append
          (indent level) key ":\n"
          (render-mapping entries (add1 level)))))
    ((yseq? value)
     (define items (yseq-items value))
     (if (null? items)
         (string-append (indent level) key ": []")
         (string-append
          (indent level) key ":\n"
          (render-sequence items (add1 level)))))
    (else
     (define scalar (scalar->yaml value))
     (if scalar
         (string-append (indent level) key ": " scalar)
         (string-append
          (indent level) key ": "
          (multiline->yaml level value))))))

(define (render-sequence items level)
  (string-join
   (map (lambda (item)
          (render-seq-item item level))
        items)
   "\n"))

(define (render-seq-pair key value level)
  (cond
    ((ymap? value)
     (define entries (ymap-entries value))
     (if (null? entries)
         (string-append (indent level) "- " key ": {}")
         (string-append
          (indent level) "- " key ":\n"
          (render-mapping entries (+ level 2)))))
    ((yseq? value)
     (define items (yseq-items value))
     (if (null? items)
         (string-append (indent level) "- " key ": []")
         (string-append
          (indent level) "- " key ":\n"
          (render-sequence items (+ level 2)))))
    (else
     (define scalar (scalar->yaml value))
     (if scalar
         (string-append (indent level) "- " key ": " scalar)
         (string-append
          (indent level) "- " key ": "
          (multiline->yaml level value))))))

(define (render-seq-item item level)
  (cond
    ((ymap? item)
     (define entries (ymap-entries item))
     (if (null? entries)
         (string-append (indent level) "- {}")
         (let* ((first-entry (car entries))
                (rest-entries (cdr entries))
                (first-line
                 (render-seq-pair (car first-entry) (cdr first-entry) level))
                (rest-lines
                 (if (null? rest-entries)
                     ""
                     (string-append
                      "\n"
                      (render-mapping rest-entries (add1 level))))))
           (string-append first-line rest-lines))))
    ((yseq? item)
     (string-append
      (indent level) "-\n"
      (render-sequence (yseq-items item) (add1 level))))
    (else
     (define scalar (scalar->yaml item))
     (if scalar
         (string-append (indent level) "- " scalar)
         (string-append
          (indent level) "- "
          (multiline->yaml level item))))))

(define (yaml->string document)
  (cond
    ((ymap? document)
     (string-append (render-mapping (ymap-entries document) 0) "\n"))
    ((yseq? document)
     (string-append (render-sequence (yseq-items document) 0) "\n"))
    (else
     (raise-arguments-error
      'yaml->string
      "expected a mapping or sequence document"
      "document" document))))
