#lang racket/base

(require racket/file
         rackunit
         "../build/k8s.rkt")

(module+ test
  (test-case "k8s manifests are generated from Racket"
    (define dir (make-temporary-file "input-foundry-k8s-test-~a" 'directory))
    (dynamic-wind
      void
      (lambda ()
        (render-k8s-directory! dir)
        (check-k8s-directory! dir))
      (lambda ()
        (delete-directory/files dir #:must-exist? #f)))))
