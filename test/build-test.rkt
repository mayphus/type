#lang racket/base

(require rackunit
         racket/file
         racket/system
         "../build.rkt")

(define (check-upload-skin-files tmp skin)
  (check-true (file-exists? (build-path tmp skin "config.yaml")))
  (check-true (file-exists? (build-path tmp skin "README.md")))
  (check-true (file-exists? (build-path tmp skin "demo.png")))
  (check-false (file-exists? (build-path tmp skin "demo.svg")))
  (check-true (file-exists? (build-path tmp skin "light" "pinyinPortrait.yaml")))
  (check-true (file-exists? (build-path tmp skin "dark" "pinyinPortrait.yaml"))))

(define (check-cskin-doc-files tmp profile-out skin)
  (define unzip-exe (find-executable-path "unzip"))
  (check-true (path? unzip-exe))
  (define extract-dir (build-path tmp "extract-cskin"))
  (make-directory* extract-dir)
  (define cskin (build-path profile-out "skins" (string-append skin ".cskin")))
  (check-true (file-exists? cskin))
  (check-true (system* unzip-exe "-q" (path->string cskin) "-d" (path->string extract-dir)))
  (check-true (file-exists? (build-path extract-dir skin "README.md")))
  (check-true (file-exists? (build-path extract-dir skin "demo.png")))
  (check-false (file-exists? (build-path extract-dir skin "demo.svg"))))

(module+ test
  (test-case "bundle shares unpacked skin directory and packaged cskin"
    (define tmp (make-temporary-file "rime-config-bundle-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (define profile-out (build-path tmp "profile"))
        (define zip-path (build-path tmp "profile.zip"))
        (define-values (_built-out _built-zip skin-dir)
          (build-bundle!
           (hash 'schemas (list "flypy") 'desktop? #f)
           "test"
           profile-out
           zip-path))
        (define skins (map path->string (directory-list skin-dir)))
        (check-equal? skins '("flypy"))
        (check-upload-skin-files skin-dir "flypy")
        (check-cskin-doc-files tmp profile-out "flypy"))
      (lambda ()
        (delete-directory/files tmp #:must-exist? #f))))

  (test-case "all generated upload skins include demo assets"
    (define tmp (make-temporary-file "rime-config-all-skins-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (define-values (_built-out _built-zip skin-dir)
          (build-bundle!
           (hash 'schemas "all" 'desktop? #f 'skip-default-custom #t)
           "test-all"
           (build-path tmp "profile")
           (build-path tmp "profile.zip")))
        (define skins (map path->string (directory-list skin-dir)))
        (check-not-equal? skins '())
        (for ([skin (in-list skins)])
          (check-upload-skin-files skin-dir skin)))
      (lambda ()
        (delete-directory/files tmp #:must-exist? #f)))))
