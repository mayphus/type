#lang racket/base

(require "families/flypy.rkt")

(flypy-family
  (dictionary luna_pinyin)
  (keyboard-layouts flypy)

  (variant flypy_ice
    (name "小鶴雙拼-霧凇")
    (dictionary ice)
    (keyboard-layouts flypy)))
