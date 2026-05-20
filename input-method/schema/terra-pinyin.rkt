#lang racket/base
(require "../../dsl/schema.rkt")

(define-schema "terra-pinyin" #:category "full-pinyin"
         #:en-name "Terra Pinyin" #:zh-name "地球拼音"
         #:en-description "Full-pinyin Mandarin input with tone-number support and matching Yuanshu layout previews."
         #:zh-description "支援聲調數字的全拼普通話輸入，並提供元書鍵盤佈局預覽。")
