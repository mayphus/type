#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "double-pinyin-mspy" #:slug "double-pinyin-mspy" #:category "double-pinyin"
         #:en-name "Double Pinyin: MSPY" #:zh-name "微軟雙拼"
         #:en-description "Upstream Rime double-pinyin schema using the Microsoft layout."
         #:zh-description "上游 Rime 微軟雙拼方案。")
