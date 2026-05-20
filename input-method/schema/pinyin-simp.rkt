#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "pinyin-simp" #:category "full-pinyin"
         #:en-name "Pinyin Simplified" #:zh-name "袖珍簡化字拼音"
         #:en-description "Supporting simplified pinyin schema used by upstream Wubi packages."
         #:zh-description "上游五筆方案使用的簡化字拼音反查支援方案。")
