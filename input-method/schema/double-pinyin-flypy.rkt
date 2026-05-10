#lang racket/base
(require "../define-schema.rkt")

(define-schema "double-pinyin-flypy" #:category "double-pinyin"
         #:en-name "Flypy" #:zh-name "小鶴雙拼"
         #:en-description "Flypy double pinyin with Rime config and Yuanshu keyboard layout previews."
         #:zh-description "小鶴方案，提供 Rime 設定與元書鍵盤佈局預覽。")
