#lang racket/base

(require racket/list
         racket/string
         "../core/methods.rkt"
         "../core/schemas.rkt"
         "paths.rkt")

(provide generated-config-ids
         schema-module-ref
         read-schema-deps
         read-schema-artifacts
         read-schema-keyboard-layouts
         read-schema-mobile-skins
         read-schema-name-from-yaml
         read-schema-description
         profile-artifact
         named-rime-profile
         list-static-schema-ids
         profile-schema-list
         resolve-schemas
         compute-assets)

(define (schema-module-path schema)
  (build-path rime-source-dir (string-append (rime-schema-source-id schema) ".rkt")))

(define (schema-module-ref schema prop [default #f])
  (define source (rime-schema-source-id schema))
  (define rkt (schema-module-path schema))
  (if (file-exists? rkt)
      (if (equal? source schema)
          (dynamic-require rkt prop (lambda () default))
          (let ([meta (dynamic-require rkt 'schema-meta (lambda () #f))])
            (if (hash? meta)
                (hash-ref (hash-ref meta schema
                                    (hash-ref meta (rime-schema-config-id schema) (hash)))
                          prop
                          (lambda ()
                            (dynamic-require rkt prop (lambda () default))))
                (dynamic-require rkt prop (lambda () default)))))
      default))

(define yuanshu-profiles-dir (build-path profiles-dir "yuanshu"))

(define all-mobile-profile
  (hash 'schemas "all"
        'artifact "yuanshu"
        'skip-default-custom #t))

(define (find-profile-path name)
  (for/or ([base (list profiles-dir
                       yuanshu-profiles-dir
                       (build-path profiles-dir "customer")
                       (build-path yuanshu-profiles-dir "customer"))])
    (define p (build-path base (string-append name ".rkt")))
    (and (file-exists? p) p)))

(define (load-profile name)
  (define path (or (find-profile-path name)
                   (error 'build "Profile '~a' not found" name)))
  (dynamic-require path 'profile))

(define (named-rime-profile name)
  (cond
    [(equal? name "all") all-mobile-profile]
    [else (load-profile name)]))

(define (read-schema-name-from-yaml schema)
  (schema-name schema))

(define (read-schema-description schema)
  (schema-module-ref schema 'schema-summary
                     (schema-description schema)))

(define (read-schema-deps schema)
  (schema-module-ref schema 'schema-deps
                     (rime-schema-deps schema)))

(define (read-schema-artifacts schema)
  (define artifacts (schema-module-ref schema 'schema-artifacts
                                       (rime-schema-artifacts schema)))
  (cond
    [(not artifacts) '()]
    [(list? artifacts) artifacts]
    [else (list artifacts)]))

(define (read-schema-keyboard-layouts schema)
  (define layouts (schema-module-ref schema 'keyboard-layouts
                                     (schema-module-ref schema 'mobile-skins
                                                        (rime-schema-keyboard-layouts schema))))
  (cond
    [(not layouts) '()]
    [(list? layouts) layouts]
    [else (list layouts)]))

(define read-schema-mobile-skins read-schema-keyboard-layouts)

(define (schema-supports-artifact? schema artifact)
  (member artifact (read-schema-artifacts schema)))

(define (profile-artifact profile)
  (define artifact (hash-ref profile 'artifact #f))
  (cond
    [(or (equal? artifact "rime") (equal? artifact 'rime)) "rime"]
    [(or (equal? artifact "yuanshu") (equal? artifact 'yuanshu)) "yuanshu"]
    [(hash-has-key? profile 'desktop?)
     (if (hash-ref profile 'desktop? #f) "rime" "yuanshu")]
    [else "rime"]))

(define (list-static-schema-ids)
  (filter-map
   (lambda (f)
     (define name (path->string f))
     (and (regexp-match? #rx"\\.schema\\.yaml$" name)
          (regexp-replace #rx"\\.schema\\.yaml$" name "")))
   (directory-list rime-dir)))

(define (profile-schema-list profile)
  (define raw (hash-ref profile 'schemas '()))
  (define lst (if (list? raw) raw (list raw)))
  (if (member "all" lst)
      (map input-method-recipe-id input-method-recipes)
      lst))

(define (expand-schema-deps schemas)
  (let loop ([queue schemas] [resolved '()])
    (if (null? queue)
        (reverse resolved)
        (let ([s (car queue)])
          (if (member s resolved)
              (loop (cdr queue) resolved)
              (loop (append (cdr queue)
                            (filter (lambda (d) (not (member d resolved)))
                                    (read-schema-deps s)))
                    (cons s resolved)))))))

(define (valid-schema-id? s)
  (and (string? s) (regexp-match? #rx"^[a-zA-Z0-9_-]+$" s)))

(define (resolve-schemas profile)
  (define raw
    (let ([lst (profile-schema-list profile)])
      (for ([id lst])
        (unless (valid-schema-id? id)
          (error 'resolve-schemas "Invalid schema id: ~v" id)))
      lst))
  (define expanded (expand-schema-deps raw))
  (define artifact (profile-artifact profile))
  (define filtered
    (filter (lambda (s) (schema-supports-artifact? s artifact)) expanded))
  (remove-duplicates filtered))

(define (compute-assets schemas profile)
  (define extra-rime  (hash-ref profile 'extra-src-files  '()))
  (define artifact (profile-artifact profile))

  (define gen-yaml  '())
  (define rime-yaml '())
  (define rime-dirs '())
  (define keyboard-layouts '())

  (define (add-gen!       f) (set! gen-yaml  (cons f gen-yaml)))
  (define (add-rime-yaml! f) (set! rime-yaml (cons f rime-yaml)))
  (define (add-rime-dir!  d) (set! rime-dirs (cons d rime-dirs)))
  (define (add-keyboard-layout! layout)
    (set! keyboard-layouts (cons layout keyboard-layouts)))

  (for ([schema schemas])
    (define source (rime-schema-config-id schema))
    (cond
      [(member schema generated-config-ids)
       (add-gen! (string-append source ".schema.yaml"))]
      [(file-exists? (build-path rime-dir (string-append source ".schema.yaml")))
       (add-rime-yaml! (string-append source ".schema.yaml"))])
    (cond
      [(member schema generated-config-ids)
       (add-gen! (string-append source ".custom.yaml"))]
      [(file-exists? (build-path rime-dir (string-append source ".custom.yaml")))
       (add-rime-yaml! (string-append source ".custom.yaml"))]))

  (for ([schema schemas])
    (for ([f (schema-module-ref schema 'static-dep-files '())]) (add-rime-yaml! f))
    (for ([f (rime-schema-extra-files schema)]) (add-rime-yaml! f))
    (for ([d (schema-module-ref schema 'static-dep-dirs  '())]) (add-rime-dir!  d))
    (for ([d (rime-schema-extra-dirs schema)]) (add-rime-dir! d)))

  (add-gen! "yuanshu_shared.yaml")
  (for ([f extra-rime]) (add-rime-yaml! f))

  (when (equal? artifact "yuanshu")
    (define selected-keyboard-layout-schemas
      (filter (lambda (schema) (schema-supports-artifact? schema artifact))
              (profile-schema-list profile)))
    (for ([layout (append-map read-schema-keyboard-layouts selected-keyboard-layout-schemas)])
      (add-keyboard-layout! layout)))

  (values (remove-duplicates (reverse gen-yaml))
          (remove-duplicates (reverse rime-yaml))
          (remove-duplicates (reverse rime-dirs))
          (remove-duplicates (reverse keyboard-layouts))))
