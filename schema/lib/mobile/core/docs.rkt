#lang racket/base

(require racket/string
         "preview-png.rkt"
         "preview-svg.rkt")

(provide (struct-out skin-meta)
         make-skin-meta
         make-skin-demo-files
         make-skin-doc-files)

(struct skin-meta (slug english-name chinese-name summary features) #:transparent)

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

(define (demo-svg meta preview-spec)
  (define light-preview
    (if (and (hash? preview-spec) (hash-has-key? preview-spec 'dark))
        (hash-remove preview-spec 'dark)
        preview-spec))
  (demo-preview-svg (skin-meta-chinese-name meta) light-preview))

(define (make-skin-demo-files meta preview-spec)
  (if (and preview-spec
           (string=? (or (getenv "RIME_RENDER_SKIN_DOCS") "") "1"))
      (with-handlers ([exn:fail?
                       (lambda (_)
                         (hash))])
        (define svg (demo-svg meta preview-spec))
        (hash "demo.svg" svg
              "demo.png" (demo-preview-png-bytes (skin-meta-chinese-name meta) preview-spec)))
      (hash)))

(define (make-skin-doc-files meta preview-spec)
  (define readme (render-readme meta))
  (if (and preview-spec
           (string=? (or (getenv "RIME_RENDER_SKIN_DOCS") "") "1"))
      (with-handlers ([exn:fail?
                       (lambda (_)
                         (hash "README.md" readme))])
        (define svg (demo-svg meta preview-spec))
        (hash "README.md" readme
              "demo.svg" svg
              "demo.png" (demo-preview-png-bytes (skin-meta-chinese-name meta) preview-spec)))
      (hash "README.md" readme)))
