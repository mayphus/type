#lang racket/base

(require racket/string
         racket/runtime-path)

(provide (struct-out keyboard-layout-meta)
         make-keyboard-layout-meta
         make-keyboard-layout-doc-files
         skin-meta
         skin-meta?
         skin-meta-slug
         skin-meta-english-name
         skin-meta-chinese-name
         skin-meta-summary
         skin-meta-features
         make-skin-meta
         make-skin-doc-files)

(struct keyboard-layout-meta (slug english-name chinese-name summary features) #:transparent)

(define skin-meta keyboard-layout-meta)
(define skin-meta? keyboard-layout-meta?)
(define skin-meta-slug keyboard-layout-meta-slug)
(define skin-meta-english-name keyboard-layout-meta-english-name)
(define skin-meta-chinese-name keyboard-layout-meta-chinese-name)
(define skin-meta-summary keyboard-layout-meta-summary)
(define skin-meta-features keyboard-layout-meta-features)

(define-runtime-path preview-png-path "preview-png.rkt")

(define (demo-preview-png-bytes title preview-spec)
  ((dynamic-require preview-png-path 'demo-preview-png-bytes) title preview-spec))

(define (make-keyboard-layout-meta #:slug slug
                                   #:english-name english-name
                                   #:chinese-name chinese-name
                                   #:summary summary
                                   #:features [features '()])
  (keyboard-layout-meta slug english-name chinese-name summary features))

(define make-skin-meta make-keyboard-layout-meta)

(define (render-readme meta)
  (define features (keyboard-layout-meta-features meta))
  (string-append
   "# "
   (keyboard-layout-meta-english-name meta)
   " ("
   (keyboard-layout-meta-chinese-name meta)
   ")\n\n"
   (keyboard-layout-meta-summary meta)
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
   "This README and `demo.png` are generated from the keyboard layout metadata.\n"))

(define (make-keyboard-layout-doc-files meta preview-spec #:render-demo? [render-demo? #f])
  (define readme (render-readme meta))
  (if (and preview-spec
           render-demo?)
      (hash "README.md" readme
            "demo.png" (demo-preview-png-bytes (keyboard-layout-meta-chinese-name meta) preview-spec))
      (hash "README.md" readme)))

(define make-skin-doc-files make-keyboard-layout-doc-files)
