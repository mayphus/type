#lang racket/base

(require "lib/flypy.rkt")

(flypy-family
  (dictionary luna_pinyin)
  (keyboard-layouts flypy)

  (variant flypy_ice
    (name "小鶴雙拼-霧凇")
    (dictionary ice)
    (artifacts yuanshu)
    (keyboard-layouts flypy))

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
      (centers
        [abc          0.5  0.28]
        [flypy-single 0.5  0.56]
        [flypy-top    0.5  0.47]
        [flypy-bottom 0.5  0.63])
      (fonts
        [abc          11   #:secondary]
        [flypy-single 18.5 #:weight bold]
        [flypy-double 13   #:weight bold])))

  (keyboard-layout hybrid
    (meta
      (name "QuadHarmonic Keyboard" "四合一鍵盤")
      (summary "A hybrid Yuanshu keyboard layout that combines Flypy, Cangjie 6, ABC, and symbol legends on one phone layout.")
      (features
        "Flypy and Cangjie 6 legends on shared phone keys"
        "ABC and symbol hints"
        "Standard iPad pinyin, numeric, and symbolic pages"))
    (phone-layout
      (layers abc cangjie flypy symbol)
      (centers
        [abc          0.72 0.40]
        [cangjie      0.37 0.34]
        [flypy-single 0.5  0.74]
        [flypy-top    0.5  0.68]
        [flypy-bottom 0.5  0.79]
        [symbol       0.73 0.24])
      (fonts
        [abc           10.5 #:secondary]
        [cangjie       15.5]
        [symbol         8.5]
        [flypy-single  12]
        [flypy-double   7.25]))
    (ipad-layout standard-18)))
