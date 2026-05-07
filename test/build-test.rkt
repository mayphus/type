#lang racket/base

(require rackunit
         racket/file
         "../build.rkt")

(module+ test
  (test-case "profile builds unpacked skin directories for direct Yuanshu upload"
    (define tmp (make-temporary-file "rime-config-skins-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (define skins
          (build-profile-skin-directories!
           (hash 'schemas (list "flypy") 'desktop? #f)
           "test"
           tmp))
        (check-equal? skins '("flypy"))
        (check-true (file-exists? (build-path tmp "flypy" "config.yaml")))
        (check-true (file-exists? (build-path tmp "flypy" "light" "pinyinPortrait.yaml")))
        (check-true (file-exists? (build-path tmp "flypy" "dark" "pinyinPortrait.yaml")))
        (check-false (file-exists? (build-path tmp "flypy.cskin"))))
      (lambda ()
        (delete-directory/files tmp #:must-exist? #f)))))
