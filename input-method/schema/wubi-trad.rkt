#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "wubi-trad" #:category "shape"
         #:en-name "Wubi Traditional" #:zh-name "五筆·簡入繁出"
         #:en-description "Upstream Rime Wubi schema for simplified input with traditional output."
         #:zh-description "上游 Rime 五筆簡入繁出方案。")
