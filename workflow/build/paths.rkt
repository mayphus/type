#lang racket/base

(require racket/path
         racket/runtime-path)

(provide root-dir
         rime-source-dir
         rime-dir
         profiles-dir
         output-dir
         yuanshu-skin-lang-path
         zip-exe)

(define-runtime-path raw-root-dir "../..")
(define root-dir (simplify-path raw-root-dir))
(define rime-source-dir (build-path root-dir "targets" "rime"))
(define rime-dir     (build-path root-dir "assets" "rime"))
(define profiles-dir (build-path root-dir "profiles"))
(define output-dir   (build-path root-dir "output" "rime"))
(define-runtime-path yuanshu-skin-lang-path "../../targets/yuanshu/skin/lang.rkt")

(define zip-exe (find-executable-path "zip"))
