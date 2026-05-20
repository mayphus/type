#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "double-pinyin-pyjj" #:slug "double-pinyin-pyjj" #:category "double-pinyin"
         #:en-name "Double Pinyin: PYJJ" #:zh-name "拼音加加雙拼"
         #:en-description "Upstream Rime double-pinyin schema using the Pinyin Jiajia layout."
         #:zh-description "上游 Rime 拼音加加雙拼方案。")
