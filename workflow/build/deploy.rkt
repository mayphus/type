#lang racket/base

(require racket/file
         racket/path
         racket/set
         racket/string
         racket/system
         "paths.rkt"
         "profile.rkt"
         "schema.rkt"
         "util.rkt")

(provide deploy-desktop!)

(define squirrel-binary
  "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel")

(define rime-protected-rx
  (list #rx"\\.userdb(/|$)"
        #rx"(^|/)user\\.yaml$"
        #rx"(^|/)installation\\.yaml$"
        #rx"\\.bin$"
        #rx"(^|/)sync(/|$)"
        #rx"(^|/)build(/|$)"))

(define (rime-protected? rel-path)
  (define s (if (path? rel-path) (path->string rel-path) rel-path))
  (ormap (lambda (rx) (regexp-match? rx s)) rime-protected-rx))

(define rime-managed-exts '(".yaml" ".txt"))

(define (rime-managed? rel-path)
  (define s (if (path? rel-path) (path->string rel-path) rel-path))
  (ormap (lambda (ext) (string-suffix? s ext)) rime-managed-exts))

(define (sync-to-dir! build-out target-dir)
  (define deploy-set (list->set (list-files-relative build-out)))

  (for ([rel (list-files-relative target-dir)])
    (when (and (rime-managed? rel)
               (not (rime-protected? rel))
               (not (set-member? deploy-set rel)))
      (define victim (build-path target-dir rel))
      (printf "Removing stale: ~a\n" rel)
      (delete-file victim)))

  (for ([rel (set->list deploy-set)])
    (copy-file! (build-path build-out rel)
                (build-path target-dir rel))))

(define (rime-deploy!)
  (cond
    [(file-exists? squirrel-binary)
     (printf "Triggering Rime deployment...\n")
     (unless (system* squirrel-binary "--reload")
       (eprintf "Warning: Rime deploy command exited with error\n"))]
    [else
     (eprintf "Warning: Squirrel not found at ~a - skipping Rime deploy\n" squirrel-binary)]))

(define (deploy-desktop! target-dir #:rime-deploy? [rime-deploy? #t])
  (when (equal? (normalize-path root-dir)
                (normalize-path target-dir))
    (error 'deploy "target is the same as the repo root - aborting"))

  (define build-out (make-temporary-file "rime-desktop-~a" 'directory))
  (dynamic-wind
    void
    (lambda ()
      (define desktop-profile (named-rime-profile "desktop"))
      (build-output! #:schemas (hash-ref desktop-profile 'schemas '())
                     #:artifact "rime"
                     #:out-dir build-out
                     #:profile-name "desktop"
                     #:extra-src-files (hash-ref desktop-profile 'extra-src-files '())
                     #:skip-default-custom? #f)

      (make-directory* target-dir)
      (sync-to-dir! build-out target-dir)
      (printf "Deployed to ~a\n" (path->string target-dir))

      (when rime-deploy? (rime-deploy!)))
    (lambda ()
      (delete-directory/files build-out #:must-exist? #f))))
