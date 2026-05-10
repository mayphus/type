#lang racket/base

(require racket/path
         racket/runtime-path)

(provide root-dir
         schema-dir
         rime-dir
         profiles-dir
         output-dir
         yuanshu-skin-lang-path
         zip-exe)

(define-runtime-path root-dir "..")
(define schema-dir   (build-path root-dir "input-method" "schema"))
(define rime-dir     (build-path root-dir "assets" "rime"))
(define profiles-dir (build-path root-dir "profiles"))
(define output-dir   (build-path root-dir "output" "rime"))
(define-runtime-path yuanshu-skin-lang-path "../yuanshu/skin/lang.rkt")

(define zip-exe (find-executable-path "zip"))
