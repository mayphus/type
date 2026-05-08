#lang racket/base

(provide keyboard-layout-definitions
         keyboard-layout-definition-ref)

(define keyboard-layout-definitions
  '((flypy
     meta
     (name "Flypy" "小鶴")
     (summary "A Yuanshu keyboard layout for Flypy double pinyin with dedicated phone and iPad layouts.")
     (features
      "Flypy legends on both phone and iPad"
      "Standard numeric and symbolic secondary pages"))
    (flypy
     phone-layout flypy)
    (flypy
     ipad-layout
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
      (flypy-double 13   #:weight bold)))

    (hybrid
     meta
     (name "QuadHarmonic Keyboard" "四合一鍵盤")
     (summary "A hybrid Yuanshu keyboard layout that combines Flypy, Cangjie 6, ABC, and symbol legends on one phone layout.")
     (features
      "Flypy and Cangjie 6 legends on shared phone keys"
      "ABC and symbol hints"
      "Standard iPad pinyin, numeric, and symbolic pages"))
    (hybrid
     phone-layout
     (layers abc cangjie flypy symbol)
     (positions
      (abc          right)
      (cangjie      top-left)
      (flypy-single bottom)
      (flypy-top    center)
      (flypy-bottom bottom)
      (symbol       top-right))
     (fonts
      (abc           10.5 #:secondary)
      (cangjie       15.5)
      (symbol         8.5)
      (flypy-single  12)
      (flypy-double   7.25)))
    (hybrid
     ipad-layout standard-18)

    (luna_pinyin
     meta
     (name "Luna Pinyin" "朙月拼音")
     (summary "A Yuanshu keyboard layout for standard full-pinyin typing.")
     (features
      "Standard QWERTY pinyin phone layout"
      "Standard iPad pinyin, numeric, and symbolic pages"))
    (luna_pinyin
     phone-layout
     (layers abc)
     (positions (abc center))
     (fonts (abc 25 #:primary #:weight bold)))
    (luna_pinyin
     ipad-layout standard-18)

    (terra_pinyin
     meta
     (name "Terra Pinyin" "地球拼音")
     (summary "A Yuanshu keyboard layout for Terra Pinyin with tone-number input.")
     (features
      "Standard QWERTY pinyin phone layout"
      "Standard iPad pinyin, numeric, and symbolic pages"))
    (terra_pinyin
     phone-layout
     (layers abc)
     (positions (abc center))
     (fonts (abc 25 #:primary #:weight bold)))
    (terra_pinyin
     ipad-layout standard-18)

    (jyut6ping3
     meta
     (name "Jyutping" "粵拼")
     (summary "A Yuanshu keyboard layout for Jyutping Cantonese input.")
     (features
      "Standard QWERTY Jyutping phone layout"
      "Standard iPad pinyin, numeric, and symbolic pages"))
    (jyut6ping3
     phone-layout
     (layers abc)
     (positions (abc center))
     (fonts (abc 25 #:primary #:weight bold)))
    (jyut6ping3
     ipad-layout standard-18)

    (cangjie6
     meta
     (name "Cangjie 6" "倉頡六代")
     (summary "A Yuanshu keyboard layout focused on Cangjie 6 labels across phone and iPad layouts.")
     (features
      "Cangjie-centered legends"
      "Standard numeric and symbolic secondary pages"))
    (cangjie6
     phone-layout
     (layers cangjie)
     (fonts (cangjie 25 #:primary #:weight bold)))
    (cangjie6
     ipad-layout
     (layers cangjie)
     (size "1.1/16")
     (fonts
      (cangjie 22.5 #:primary #:weight bold)))

    (bopomofo
     meta
     (name "Bopomofo" "注音")
     (summary "A Yuanshu keyboard layout for Bopomofo input with the standard secondary pages.")
     (features
      "Bopomofo phone layout"
      "Bundled custom iPad pages"))
    (bopomofo
     phone-layout bopomofo)

    (flypy_14
     meta
     (name "Flypy-14 Key" "小鶴-14鍵")
     (summary "A compact Yuanshu keyboard layout for the Flypy 14-key layout.")
     (features
      "14-key phone layout"
      "Standard iPad pinyin page and secondary pages"))
    (flypy_14
     phone-layout flypy-14)
    (flypy_14
     ipad-layout standard-18)

    (flypy_18
     meta
     (name "Flypy-18 Key" "小鶴-18鍵")
     (summary "A compact Yuanshu keyboard layout for the Flypy 18-key layout.")
     (features
      "18-key phone layout"
      "Standard iPad pinyin page and secondary pages"))
    (flypy_18
     phone-layout flypy-18)
    (flypy_18
     ipad-layout standard-18)

    (pinyin_14
     meta
     (name "Pinyin-14 Key" "朙月拼音-14鍵")
     (summary "A compact Yuanshu keyboard layout for the full-pinyin 14-key layout.")
     (features
      "14-key full-pinyin phone layout"
      "Standard iPad pinyin page and secondary pages"))
    (pinyin_14
     phone-layout pinyin-14)
    (pinyin_14
     ipad-layout standard-18)

    (shuffle_17
     meta
     (name "Flypy-Shuffle 17 Key" "小鶴-亂序17鍵")
     (summary "An experimental 17-key Yuanshu keyboard layout for the shuffle_17 schema family.")
     (features
      "17-key shuffled phone layout"
      "Custom iPad pages"))
    (shuffle_17
     phone-layout shuffle-17)))

(define (keyboard-layout-definition-ref layout [default #f])
  (define layout-symbol
    (cond
      [(symbol? layout) layout]
      [(string? layout) (string->symbol layout)]
      [else layout]))
  (define body
    (for/list ([clause (in-list keyboard-layout-definitions)]
               #:when (eq? (car clause) layout-symbol))
      (cdr clause)))
  (if (null? body) default body))
