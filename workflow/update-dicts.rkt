#lang racket/base

;;; Refresh vendored Rime dictionary files from upstream projects.

(require net/url
         racket/file
         racket/path
         racket/port
         racket/runtime-path
         racket/string)

(provide update-dicts!)

(define-runtime-path tools-dir ".")
(define root-dir (simplify-path (build-path tools-dir "..")))
(define rime-dir (build-path root-dir "assets" "rime"))

(struct dict-source (upstream local local-name upstream-name) #:transparent)

(define sources
  (list
   (dict-source "rime/rime-cantonese/main/jyut6ping3.chars.dict.yaml" "jyut6ping3_dicts/jyut6ping3.chars.dict.yaml" "jyut6ping3.chars" #f)
   (dict-source "rime/rime-cantonese/main/jyut6ping3.words.dict.yaml" "jyut6ping3_dicts/jyut6ping3.words.dict.yaml" "jyut6ping3.words" #f)
   (dict-source "rime/rime-cantonese/main/jyut6ping3.phrase.dict.yaml" "jyut6ping3_dicts/jyut6ping3.phrase.dict.yaml" "jyut6ping3.phrase" #f)
   (dict-source "rime/rime-cantonese/main/jyut6ping3.lettered.dict.yaml" "jyut6ping3_dicts/jyut6ping3.lettered.dict.yaml" "jyut6ping3.lettered" #f)
   (dict-source "rime/rime-cantonese/main/jyut6ping3.maps.dict.yaml" "jyut6ping3_dicts/jyut6ping3.maps.dict.yaml" "jyut6ping3.maps" #f)
   (dict-source "rime/rime-cantonese/main/essay-cantonese.txt" "jyut6ping3_dicts/essay-cantonese.txt" #f #f)
   (dict-source "rime/rime-cantonese/main/symbols_cantonese.yaml" "symbols_cantonese.yaml" #f #f)
   (dict-source "ksqsf/rime-moran/main/moran.base.dict.yaml" "moran_dicts/moran.base.dict.yaml" "moran_dicts/moran.base" "moran.base")
   (dict-source "ksqsf/rime-moran/main/moran.words.dict.yaml" "moran_dicts/moran.words.dict.yaml" "moran_dicts/moran.words" "moran.words")
   (dict-source "ksqsf/rime-moran/main/moran.tencent.dict.yaml" "moran_dicts/moran.tencent.dict.yaml" "moran_dicts/moran.tencent" "moran.tencent")
   (dict-source "ksqsf/rime-moran/main/moran.computer.dict.yaml" "moran_dicts/moran.computer.dict.yaml" "moran_dicts/moran.computer" "moran.computer")
   (dict-source "ksqsf/rime-moran/main/moran.moe.dict.yaml" "moran_dicts/moran.moe.dict.yaml" "moran_dicts/moran.moe" "moran.moe")
   (dict-source "ksqsf/rime-moran/main/moran_fixed.dict.yaml" "moran_dicts/moran_fixed.dict.yaml" "moran_dicts/moran_fixed" "moran_fixed")
   (dict-source "ksqsf/rime-moran/main/moran_fixed_simp.dict.yaml" "moran_dicts/moran_fixed_simp.dict.yaml" "moran_dicts/moran_fixed_simp" "moran_fixed_simp")))

(define (source-url source)
  (string-append "https://raw.githubusercontent.com/" (dict-source-upstream source)))

(define (local-path source)
  (build-path rime-dir (dict-source-local source)))

(define (download-text url)
  (define headers '("User-Agent: mayphus-input-foundry-dict-updater"))
  (call/input-url (string->url url)
                  get-pure-port
                  (lambda (in) (port->string in))
                  headers))

(define (validate-source source text)
  (define url (source-url source))
  (when (string=? (string-trim text) "")
    (error 'update-dicts "~a returned an empty file" url))

  (define expected-name (or (dict-source-upstream-name source)
                            (dict-source-local-name source)))
  (when expected-name
    (define expected-line (format "name: ~a" expected-name))
    (define quoted-expected-line (format "name: \"~a\"" expected-name))
    (unless (or (string-contains? text expected-line)
                (string-contains? text quoted-expected-line))
      (error 'update-dicts
             "~a does not look like ~a: missing `~a`"
             url expected-name expected-line)))

  (when (and (string-suffix? (dict-source-local source) ".dict.yaml")
             (not (string-contains? text "---")))
    (error 'update-dicts "~a does not look like a Rime dictionary" url)))

(define (adapt-to-local-layout source text)
  (define upstream-name (dict-source-upstream-name source))
  (define local-name (dict-source-local-name source))
  (cond
    [(or (not upstream-name) (equal? upstream-name local-name)) text]
    [else
     (define needles (list (format "name: ~a" upstream-name)
                           (format "name: \"~a\"" upstream-name)))
     (define needle (findf (lambda (candidate) (string-contains? text candidate)) needles))
     (if needle
         (string-replace text needle (format "name: ~a" local-name) #:all? #f)
         (error 'update-dicts
                "~a cannot be adapted to local name ~a"
                (source-url source)
                local-name))]))

(define (read-file-if-exists path)
  (and (file-exists? path)
       (file->string path)))

(define (update-one source dry-run?)
  (define text (download-text (source-url source)))
  (validate-source source text)
  (define local-text (adapt-to-local-layout source text))
  (define path (local-path source))
  (cond
    [(equal? (read-file-if-exists path) local-text)
     (printf "unchanged ~a\n" (dict-source-local source))
     #f]
    [else
     (printf "update    ~a\n" (dict-source-local source))
     (unless dry-run?
       (make-directory* (path-only path))
       (call-with-output-file path
         #:exists 'truncate/replace
         (lambda (out) (display local-text out))))
     #t]))

(define (update-dicts! #:dry-run? [dry-run? #f])
  (define changed?
    (for/fold ([changed? #f])
              ([source (in-list sources)])
      (or (update-one source dry-run?) changed?)))
  (displayln (if changed? "changed" "no changes"))
  changed?)
