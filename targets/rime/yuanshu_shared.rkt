#lang racket/base

(require "../yuanshu/patches.rkt")

(provide config-files)

(define config-files
  (make-shared-config-files))
