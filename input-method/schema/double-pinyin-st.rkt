#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "double-pinyin-st" #:slug "double-pinyin-st" #:category "double-pinyin"
         #:en-name "Double Pinyin: ST" #:zh-name "四通雙拼"
         #:en-description "Upstream Rime double-pinyin schema using the Stone layout."
         #:zh-description "上游 Rime 四通雙拼方案。")
