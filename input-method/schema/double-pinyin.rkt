#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "double-pinyin" #:slug "double-pinyin-zrm" #:category "double-pinyin"
         #:en-name "Double Pinyin: ZRM" #:zh-name "自然碼雙拼"
         #:en-description "Upstream Rime double-pinyin schema using the Ziranma layout."
         #:zh-description "上游 Rime 自然碼雙拼方案。")
