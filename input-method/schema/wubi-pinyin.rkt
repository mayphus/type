#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "wubi-pinyin" #:category "shape"
         #:en-name "Wubi Pinyin" #:zh-name "五筆·拼音"
         #:en-description "Upstream Rime Wubi schema with pinyin mixed input."
         #:zh-description "上游 Rime 五筆拼音混輸方案。")
