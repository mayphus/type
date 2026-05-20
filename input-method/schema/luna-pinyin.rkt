#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "luna-pinyin" #:category "full-pinyin"
         #:en-name "Luna Pinyin" #:zh-name "朙月拼音"
         #:en-description "Standard full-pinyin Mandarin input, available as both Rime config and Yuanshu package."
         #:zh-description "標準全拼普通話輸入方案，可輸出 Rime 設定與元書套件。")
