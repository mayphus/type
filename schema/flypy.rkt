#lang racket/base

(require "families/flypy.rkt")

(flypy-family
  (dictionary luna_pinyin)
  (keyboard-layout flypy
    (meta
     (name "Flypy" "小鶴")
     (summary "A Yuanshu keyboard layout for Flypy double pinyin with dedicated phone and iPad layouts.")
     (features
      "Flypy legends on both phone and iPad"
      "Standard numeric and symbolic secondary pages"))
    (phone-layout flypy)
    (ipad-layout
     (layers abc flypy)
     (size "1.1/16")
     (positions
      (abc          top)
      (flypy-single bottom)
      (flypy-top    center)
      (flypy-bottom bottom))
     (fonts
      (abc          11   #:secondary)
      (flypy-single 18.5 #:weight bold)
      (flypy-double 13   #:weight bold))))

  (variant flypy_ice
    (name "小鶴雙拼-霧凇")
    (dictionary ice)
    (keyboard-layouts flypy)))
