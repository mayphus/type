#lang s-exp "lib/lang.rkt"

(rime-schema bopomofo
  (name "注音")
  (keyboard-layouts bopomofo)
  (static-files "terra_pinyin.dict.yaml" "zhuyin.yaml")
  (artifacts yuanshu))
