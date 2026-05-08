#lang racket/base

(require racket/file
         racket/path
         "keyboard.rkt")

(provide module-export-ref
         write-module-files!)

(define (module-export-ref rkt-path export-sym #:fresh? [fresh? #f])
  (if (keyboard-layout-module? rkt-path)
      (keyboard-layout-module-ref rkt-path export-sym #:fresh? fresh?)
      (if fresh?
          (parameterize ([current-namespace (make-base-namespace)])
            (dynamic-require rkt-path export-sym))
          (dynamic-require rkt-path export-sym))))

(define (write-module-files! rkt-path out-dir export-sym #:fresh? [fresh? #f])
  (define files
    (let ([v (module-export-ref rkt-path export-sym #:fresh? fresh?)])
      (unless (hash? v)
        (unless (procedure? v)
          (error 'write-module-files!
                 "~a: expected ~a to be a hash or thunk, got ~v" rkt-path export-sym v)))
      (if (procedure? v) (v) v)))
  (for ([(rel-path content) (in-hash files)])
    (define target (build-path out-dir (string->path rel-path)))
    (make-directory* (path-only target))
    (call-with-output-file target #:exists 'truncate/replace
      (lambda (out)
        (cond
          [(string? content) (display content out)]
          [(bytes?  content) (write-bytes content out)]
          [else (error 'write-module-files!
                       "~a: expected string or bytes for ~a, got ~v"
                       rkt-path rel-path content)])))))
