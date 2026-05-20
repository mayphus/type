#lang racket/base

(require "../targets/yuanshu/patches.rkt")

(provide config-files)

(define config-files
  (make-shared-config-files))
