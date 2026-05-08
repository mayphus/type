#lang racket/base

(require racket/file
         racket/format
         racket/list
         racket/path
         racket/system)

(provide run!
         delete-file*
         copy-file!
         copy-dir!
         list-files-relative)

(define (run! prog . args)
  (define str-args (map (lambda (a) (if (path? a) (path->string a) (~a a))) args))
  (unless (apply system* prog str-args)
    (error 'build "Command failed: ~a ~a" prog str-args)))

(define (delete-file* p)
  (when (file-exists? p) (delete-file p)))

(define (copy-file! src dst)
  (make-directory* (path-only dst))
  (copy-file src dst #t))

(define (copy-dir! src dst)
  (when (directory-exists? dst) (delete-directory/files dst))
  (copy-directory/files src dst))

(define (list-files-relative dir)
  (let loop ([base dir] [prefix ""])
    (append-map
     (lambda (entry)
       (define full (build-path base entry))
       (define rel  (if (string=? prefix "")
                        (path->string entry)
                        (string-append prefix "/" (path->string entry))))
       (cond
         [(file-exists?      full) (list rel)]
         [(directory-exists? full) (loop full rel)]
         [else '()]))
     (directory-list base))))
