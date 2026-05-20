#lang racket/base

(require racket/file
         racket/port
         racket/string
         racket/system
         "preview-svg.rkt")

(provide demo-preview-png-bytes)

(define (light-preview preview-spec)
  (if (and (hash? preview-spec) (hash-has-key? preview-spec 'dark))
      (hash-remove preview-spec 'dark)
      preview-spec))

(define (rsvg-convert-path)
  (or (find-executable-path "rsvg-convert")
      (error 'demo-preview-png-bytes
             "rsvg-convert is required to render demo.png; install librsvg (macOS: brew install librsvg, Debian: apt-get install librsvg2-bin)")))

(define (svg->png-bytes svg)
  (define converter (rsvg-convert-path))
  (define svg-path (make-temporary-file "yuanshu-demo-~a.svg"))
  (define png-path (make-temporary-file "yuanshu-demo-~a.png"))
  (dynamic-wind
    void
    (lambda ()
      (call-with-output-file svg-path
        #:exists 'truncate/replace
        (lambda (out) (display svg out)))
      (define stderr (open-output-string))
      (define ok?
        (parameterize ([current-error-port stderr])
          (system* converter "-f" "png" "-o" (path->string png-path) (path->string svg-path))))
      (unless ok?
        (error 'demo-preview-png-bytes
               "rsvg-convert failed: ~a"
               (string-trim (get-output-string stderr))))
      (file->bytes png-path))
    (lambda ()
      (when (file-exists? svg-path) (delete-file svg-path))
      (when (file-exists? png-path) (delete-file png-path)))))

(define (demo-preview-png-bytes title preview-spec)
  (svg->png-bytes (demo-preview-svg title (light-preview preview-spec))))
