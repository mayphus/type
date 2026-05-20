#lang racket/base

(require racket/format
         racket/hash
         racket/list
         racket/string)

(provide object
         keyboard-layout-spec
         keyboard-layout-spec?
         skin-spec
         skin-spec?
         page-spec
         page-spec?
         button-spec
         button-spec?
         make-keyboard-layout
         make-skin
         make-page
         make-button
         make-keyboard-layout-files
         make-skin-files
         bundle
         bundle/strict
         array
         json-number
         json-file
         static-files
         theme-pages
         yaml-page
         render-json
         auto-ordered-page)

(define-syntax-rule (object [key value] ...)
  (list (cons key value) ...))

(define-syntax-rule (array value ...)
  (vector value ...))

(struct button-spec (name kind props) #:transparent)
(struct page-spec (name base-kind rows buttons variants overrides) #:transparent)
(struct keyboard-layout-spec (config-data pages extras) #:transparent)

(define skin-spec keyboard-layout-spec)
(define skin-spec? keyboard-layout-spec?)

(define (make-button name kind props)
  (button-spec name kind props))

(define (make-page name
                   #:base-kind base-kind
                   #:rows [rows '()]
                   #:buttons [buttons '()]
                   #:variants [variants '()]
                   #:overrides [overrides (hash)])
  (page-spec name base-kind rows buttons variants overrides))

(define (make-keyboard-layout
         #:config config-data
         #:pages [pages '()]
         #:extras [extras '()])
  (keyboard-layout-spec config-data pages extras))

(define make-skin make-keyboard-layout)

(struct json-number-val (lexeme) #:transparent)
(define json-number? json-number-val?)
(define json-number-lexeme json-number-val-lexeme)
(define (json-number lexeme)
  (unless (regexp-match? #rx"^-?[0-9]+(\\.[0-9]+(([eE][+-]?[0-9]+)?))?$" lexeme)
    (error 'json-number "invalid numeric lexeme: ~v" lexeme))
  (json-number-val lexeme))

(define (json-string value)
  (define escaped
    (regexp-replace*
     #px"[\u0000-\u001f\\\\\"]"
     value
     (lambda (match)
       (case (string-ref match 0)
         [(#\") "\\\""]
         [(#\\) "\\\\"]
         [(#\backspace) "\\b"]
         [(#\page) "\\f"]
         [(#\newline) "\\n"]
         [(#\return) "\\r"]
         [(#\tab) "\\t"]
         [else (format "\\u~4,'0x" (char->integer (string-ref match 0)))]))))
  (string-append "\"" escaped "\""))

(define (render-json value [level 0])
  (define indent (make-string (* level 3) #\space))
  (define child-indent (make-string (* (add1 level) 3) #\space))
  (cond
    [(vector? value)
     (if (zero? (vector-length value))
         "[ ]"
         (string-append
          "[\n"
          (string-join
           (for/list ([entry (in-vector value)])
             (string-append child-indent (render-json entry (add1 level))))
           ",\n")
          "\n"
          indent
          "]"))]
    [(list? value)
     (if (null? value)
         "{ }"
         (string-append
          "{\n"
          (string-join
           (for/list ([entry (in-list value)])
             (format "~a~a: ~a"
                     child-indent
                     (json-string (car entry))
                     (render-json (cdr entry) (add1 level))))
           ",\n")
          "\n"
          indent
          "}"))]
    [(eq? value 'null) "null"]
    [(json-number? value) (json-number-lexeme value)]
    [(string? value) (json-string value)]
    [(boolean? value) (if value "true" "false")]
    [(number? value) (~a value)]
    [else (error 'render-json "unsupported json value: ~v" value)]))

(define (bundle . file-groups)
  (for/fold ([acc (hash)]) ([group (in-list file-groups)])
    (hash-union acc group #:combine/key (lambda (_ left _right) left))))

(define (bundle/strict . file-groups)
  (for/fold ([acc (hash)]) ([group (in-list file-groups)])
    (hash-union acc group #:combine/key (lambda (key _left _right)
                                          (error 'bundle/strict "duplicate key: ~v" key)))))

(define (page-group->hash group)
  (cond
    [(hash? group) group]
    [(page-spec? group) (page-spec-overrides group)]
    [else
     (error 'make-keyboard-layout-files "expected page hash or page-spec, got ~v" group)]))

(define (json-file path value)
  (hash path (string-append (render-json value) "\n")))

(define (yaml-page theme name)
  (string-append theme "/" name ".yaml"))

(define (theme-pages names)
  (append
   (for/list ([name (in-list names)])
     (yaml-page "light" name))
   (for/list ([name (in-list names)])
     (yaml-page "dark" name))))

(define (auto-ordered-page combined)
  (for/list ([key (in-list (sort (hash-keys combined) string<?))])
    (cons key (hash-ref combined key))))

(define (make-keyboard-layout-files spec)
  (unless (keyboard-layout-spec? spec)
    (error 'make-keyboard-layout-files "expected keyboard-layout-spec, got ~v" spec))
  (apply bundle
         (append
          (for/list ([group (in-list (keyboard-layout-spec-pages spec))])
            (page-group->hash group))
          (for/list ([group (in-list (keyboard-layout-spec-extras spec))])
            (page-group->hash group))
          (list (json-file "config.yaml" (keyboard-layout-spec-config-data spec))))))

(define make-skin-files make-keyboard-layout-files)

(define (static-files store paths)
  (for/hash ([path (in-list paths)])
    (values path
            (string-append
             (render-json
              (hash-ref store path
                        (lambda ()
                          (error 'static-files "missing frozen page content for ~a" path))))
             "\n"))))
