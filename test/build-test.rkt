#lang racket/base

(require rackunit
         racket/file
         racket/string
         racket/system
         "../build.rkt")

(define (check-upload-layout-files tmp layout)
  (check-true (file-exists? (build-path tmp layout "config.yaml")))
  (check-true (file-exists? (build-path tmp layout "README.md")))
  (check-true (file-exists? (build-path tmp layout "demo.png")))
  (check-false (file-exists? (build-path tmp layout "demo.svg")))
  (check-true (file-exists? (build-path tmp layout "light" "pinyinPortrait.yaml")))
  (check-true (file-exists? (build-path tmp layout "dark" "pinyinPortrait.yaml"))))

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

(define (check-downloaded-cskin-doc-files tmp extract-profile skin)
  (define unzip-exe (find-executable-path "unzip"))
  (check-true (path? unzip-exe))
  (define extract-dir (build-path tmp "extract-downloaded-cskin"))
  (make-directory* extract-dir)
  (define cskin (build-path extract-profile "profile" "skins" (string-append skin ".cskin")))
  (check-true (file-exists? cskin))
  (check-true (system* unzip-exe "-q" (path->string cskin) "-d" (path->string extract-dir)))
  (check-true (file-exists? (build-path extract-dir skin "README.md")))
  (check-true (file-exists? (build-path extract-dir skin "demo.png")))
  (check-false (file-exists? (build-path extract-dir skin "demo.svg"))))

(define (unzip! zip-path extract-dir)
  (define unzip-exe (find-executable-path "unzip"))
  (check-true (path? unzip-exe))
  (make-directory* extract-dir)
  (check-true (system* unzip-exe "-q" (path->string zip-path) "-d" (path->string extract-dir))))

(define (check-zip-file extract-dir . rel-parts)
  (check-true (file-exists? (apply build-path extract-dir rel-parts))))

(module+ test
  (test-case "yuanshu artifact shares unpacked layout directory and packaged cskin"
    (define tmp (make-temporary-file "rime-config-bundle-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (define profile-out (build-path tmp "profile"))
        (define zip-path (build-path tmp "profile.zip"))
        (define-values (_built-out _built-zip layout-dir)
          (build-bundle!
           (hash 'schemas (list "flypy") 'artifact "yuanshu")
           "test"
           profile-out
           zip-path))
        (define layouts (map path->string (directory-list layout-dir)))
        (check-equal? layouts '("flypy"))
        (check-true (file-exists? zip-path))
        (define extract-profile (build-path tmp "extract-profile"))
        (unzip! zip-path extract-profile)
        (check-zip-file extract-profile "profile" "flypy.schema.yaml")
        (check-zip-file extract-profile "profile" "flypy.custom.yaml")
        (check-zip-file extract-profile "profile" "cangjie6.custom.yaml")
        (check-zip-file extract-profile "profile" "default.custom.yaml")
        (check-zip-file extract-profile "profile" "skins" "flypy.cskin")
        (check-false (directory-exists? (build-path extract-profile "Skins")))
        (check-downloaded-cskin-doc-files tmp extract-profile "flypy")
        (check-upload-layout-files layout-dir "flypy")
        (check-cskin-doc-files tmp profile-out "flypy"))
      (lambda ()
        (delete-directory/files tmp #:must-exist? #f))))

  (test-case "all generated upload keyboard layouts include demo assets"
    (define tmp (make-temporary-file "rime-config-all-skins-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (define-values (_built-out _built-zip layout-dir)
          (build-bundle!
           (hash 'schemas "all" 'artifact "yuanshu" 'skip-default-custom #t)
           "test-all"
           (build-path tmp "profile")
           (build-path tmp "profile.zip")))
        (define layouts (map path->string (directory-list layout-dir)))
        (check-not-equal? layouts '())
        (for ([layout (in-list layouts)])
          (check-upload-layout-files layout-dir layout)))
      (lambda ()
        (delete-directory/files tmp #:must-exist? #f))))

  (test-case "rime artifact excludes keyboard layout packages and yuanshu-only schemas"
    (define tmp (make-temporary-file "rime-config-rime-artifact-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (define profile-out (build-path tmp "profile"))
        (define zip-path (build-path tmp "profile.zip"))
        (define-values (_built-out _built-zip _layout-dir)
          (build-bundle!
           (hash 'schemas (list "pinyin_14" "flypy")
                 'artifact "rime"
                 'extra-src-files '("squirrel.custom.yaml"))
           "test-rime"
           profile-out
           zip-path))
        (check-false (file-exists? (build-path profile-out "pinyin_14.schema.yaml")))
        (check-false (directory-exists? (build-path profile-out "skins")))
        (define extract-profile (build-path tmp "extract-rime-profile"))
        (unzip! zip-path extract-profile)
        (check-false (file-exists? (build-path extract-profile "profile" "pinyin_14.schema.yaml")))
        (check-false (directory-exists? (build-path extract-profile "profile" "skins"))))
      (lambda ()
        (delete-directory/files tmp #:must-exist? #f))))

  (test-case "flypy ice download selects the rime-ice dictionary variant"
    (define tmp (make-temporary-file "rime-config-flypy-ice-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (define profile-out (build-path tmp "profile"))
        (define zip-path (build-path tmp "profile.zip"))
        (define-values (_built-out _built-zip _layout-dir)
          (build-bundle!
           (hash 'schemas (list "flypy_ice")
                 'artifact "rime"
                 'extra-src-files '("squirrel.custom.yaml"))
           "test-flypy-ice"
           profile-out
           zip-path))
        (define variant-yaml (file->string (build-path profile-out "flypy_ice.schema.yaml")))
        (define default-custom (file->string (build-path profile-out "default.custom.yaml")))
        (check-true (string-contains? variant-yaml "dictionary: rime_ice"))
        (check-true (string-contains? default-custom "schema: flypy_ice"))
        (check-false (regexp-match? #rx"schema: flypy\n" default-custom))
        (check-true (file-exists? (build-path profile-out "rime_ice.dict.yaml")))
        (check-true (directory-exists? (build-path profile-out "rime_ice_dicts")))
        (define extract-profile (build-path tmp "extract-flypy-ice-profile"))
        (unzip! zip-path extract-profile)
        (check-zip-file extract-profile "profile" "flypy_ice.schema.yaml")
        (check-zip-file extract-profile "profile" "rime_ice.dict.yaml"))
      (lambda ()
        (delete-directory/files tmp #:must-exist? #f))))

  (test-case "static upstream schemas copy their dictionaries and dependency assets"
    (define tmp (make-temporary-file "rime-config-static-upstream-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (define profile-out (build-path tmp "profile"))
        (define zip-path (build-path tmp "profile.zip"))
        (define-values (_built-out _built-zip _layout-dir)
          (build-bundle!
           (hash 'schemas (list "double_pinyin" "wubi86" "quick5" "cangjie5")
                 'artifact "rime")
           "test-static-upstream"
           profile-out
           zip-path))
        (for ([file (in-list '("double_pinyin.schema.yaml"
                               "stroke.schema.yaml"
                               "stroke.dict.yaml"
                               "wubi86.schema.yaml"
                               "wubi86.dict.yaml"
                               "pinyin_simp.schema.yaml"
                               "pinyin_simp.dict.yaml"
                               "quick5.schema.yaml"
                               "quick5.dict.yaml"
                               "cangjie5.schema.yaml"
                               "cangjie5.dict.yaml"
                               "luna_quanpin.schema.yaml"
                               "pinyin.yaml"))])
          (check-true (file-exists? (build-path profile-out file)) file)))
      (lambda ()
        (delete-directory/files tmp #:must-exist? #f))))

  (test-case "static upstream schemas reuse preview keyboard layouts"
    (check-equal? (read-schema-keyboard-layouts "double_pinyin") '("luna_pinyin"))
    (check-equal? (read-schema-keyboard-layouts "double_pinyin_flypy") '("flypy"))
    (check-equal? (read-schema-keyboard-layouts "cangjie5") '("cangjie6"))
    (check-equal? (read-schema-keyboard-layouts "quick5") '("cangjie6"))
    (check-equal? (read-schema-keyboard-layouts "wubi86") '("luna_pinyin")))

  (test-case "legacy desktop flag still maps to yuanshu artifact behavior"
    (define tmp (make-temporary-file "rime-config-legacy-artifact-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (define-values (_built-out _built-zip layout-dir)
          (build-bundle!
           (hash 'schemas (list "flypy") 'desktop? #f)
           "legacy-yuanshu"
           (build-path tmp "profile")
           (build-path tmp "profile.zip")))
        (check-true (directory-exists? layout-dir))
        (check-true (file-exists? (build-path tmp "profile" "skins" "flypy.cskin"))))
      (lambda ()
        (delete-directory/files tmp #:must-exist? #f)))))
