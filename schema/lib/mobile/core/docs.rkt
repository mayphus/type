#lang racket/base

(require racket/string
         racket/runtime-path)

(provide (struct-out skin-meta)
         make-skin-meta
         make-skin-doc-files)

(struct skin-meta (slug english-name chinese-name summary features) #:transparent)

(define-runtime-path preview-png-path "preview-png.rkt")

(define (demo-preview-png-bytes title preview-spec)
  ((dynamic-require preview-png-path 'demo-preview-png-bytes) title preview-spec))

(define (make-skin-meta #:slug slug
                        #:english-name english-name
                        #:chinese-name chinese-name
                        #:summary summary
                        #:features [features '()])
  (skin-meta slug english-name chinese-name summary features))

(define (render-readme meta)
  (define features (skin-meta-features meta))
  (string-append
   "# "
   (skin-meta-english-name meta)
   " ("
   (skin-meta-chinese-name meta)
   ")\n\n"
   (skin-meta-summary meta)
   "\n\n"
   (if (null? features)
       ""
       (string-append
        "## Features\n\n"
        (string-join
         (for/list ([feature (in-list features)])
           (string-append "- " feature))
         "\n")
        "\n\n"))
   "This README and `demo.png` are generated from the skin metadata.\n"))

(define (make-skin-doc-files meta preview-spec #:render-demo? [render-demo? #f])
  (define readme (render-readme meta))
  (if (and preview-spec
           render-demo?)
      (hash "README.md" readme
            "demo.png" (demo-preview-png-bytes (skin-meta-chinese-name meta) preview-spec))
      (hash "README.md" readme)))
