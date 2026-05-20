#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "double-pinyin-abc" #:slug "double-pinyin-abc" #:category "double-pinyin"
         #:en-name "Double Pinyin: ABC" #:zh-name "智能ABC雙拼"
         #:en-description "Upstream Rime double-pinyin schema using the Intelligent ABC layout."
         #:zh-description "上游 Rime 智能 ABC 雙拼方案。")
