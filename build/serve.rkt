#lang racket/base

(require racket/date
         racket/file
         racket/list
         racket/match
         racket/path
         racket/port
         racket/string)

(define racket-exe
  (or (find-executable-path "racket")
      (error 'dev-web "racket not found in PATH")))

(define watch-roots
  '("build"
    "catalog"
    "lang"
    "targets"
    "web"
    "lib"
    "type.rkt"))

(define ignored-dir-names
  '("compiled" ".git" ".DS_Store"))

(define (ignored-path? path)
  (member (path->string (file-name-from-path path)) ignored-dir-names))

(define (walk path)
  (cond
    [(ignored-path? path) '()]
    [(directory-exists? path)
     (cons path (append-map walk (directory-list path #:build? #t)))]
    [(file-exists? path) (list path)]
    [else '()]))

(define (snapshot)
  (for/hash ([path (in-list (append-map walk (map string->path watch-roots)))])
    (values (path->complete-path path)
            (file-or-directory-modify-seconds path #f (lambda () 0)))))

(define (changed? before after)
  (or (not (= (hash-count before) (hash-count after)))
      (for/or ([(path mtime) (in-hash after)])
        (not (equal? mtime (hash-ref before path #f))))))

(define (timestamp-token)
  (number->string (current-inexact-milliseconds)))

(define (log fmt . args)
  (apply printf (string-append "[dev-web] " fmt "\n") args)
  (flush-output))

(define current-server #f)

(define (stop-server!)
  (when current-server
    (define proc current-server)
    (set! current-server #f)
    (subprocess-kill proc #t)
    (subprocess-wait proc)))

(define (start-server!)
  (define token (timestamp-token))
  (define-values (proc _stdout _stdin _stderr)
    (subprocess
     (current-output-port)
     #f
     (current-error-port)
     (find-executable-path "env")
     "INPUT_FOUNDRY_DEV_RELOAD=1"
     (string-append "INPUT_FOUNDRY_DEV_RELOAD_TOKEN=" token)
     (path->string racket-exe)
     "main.rkt"
     "serve"))
  (set! current-server proc)
  (log "started Racket web server with reload token ~a" token))

(define (restart-server!)
  (stop-server!)
  (start-server!))

(define (main)
  (define port (or (getenv "PORT") "5001"))
  (log "watching for changes; visit http://localhost:~a" port)
  (start-server!)
  (let loop ([last (snapshot)])
    (sleep 0.7)
    (define next (snapshot))
    (cond
      [(changed? last next)
       (log "change detected; restarting")
       (restart-server!)
       (loop (snapshot))]
      [else
       (loop next)])))

(with-handlers ([exn:break?
                 (lambda (exn)
                   (stop-server!)
                   (log "stopped"))])
  (main))
