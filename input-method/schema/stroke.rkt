#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "stroke" #:category "shape"
         #:en-name "Stroke" #:zh-name "五筆畫"
         #:en-description "Supporting five-stroke lookup schema used by upstream double-pinyin and Wubi packages."
         #:zh-description "上游雙拼與五筆方案使用的五筆畫反查支援方案。")
