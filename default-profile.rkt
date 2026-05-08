#lang racket/base

(provide default-rime-profile
         default-desktop-profile)

(define default-rime-profile
  (hash 'schemas         '("cangjie5"
                           "cangjie5_express"
                           "cangjie6"
                           "double_pinyin"
                           "double_pinyin_abc"
                           "double_pinyin_flypy"
                           "double_pinyin_mspy"
                           "double_pinyin_pyjj"
                           "double_pinyin_st"
                           "jyut6ping3"
                           "bopomofo"
                           "flypy"
                           "luna_pinyin"
                           "quick5"
                           "terra_pinyin"
                           "wubi86"
                           "wubi_pinyin"
                           "wubi_trad")
        'extra-src-files '("squirrel.custom.yaml")
        'artifact        "rime"))

(define default-desktop-profile default-rime-profile)
