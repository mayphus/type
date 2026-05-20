#lang racket/base

(require "../../dsl/schema.rkt")

(define-schema "bopomofo" #:category "zhuyin"
         #:en-name "Zhuyin" #:zh-name "注音"
         #:en-description "Zhuyin input for Mandarin, arranged for standard and Yuanshu keyboard layouts."
         #:zh-description "注音符號普通話輸入，配置為元書鍵盤佈局。")
