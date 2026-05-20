#lang racket/base

(require "lang/type.rkt")

(provide input-methods)

(define-input-methods input-methods
  (input-method "double-pinyin-flypy"
    #:category "double-pinyin"
    #:name '("Flypy" "小鶴雙拼")
    #:description '("Flypy double pinyin with Rime config and Yuanshu keyboard layout previews."
                    "小鶴方案，提供 Rime 設定與元書鍵盤佈局預覽。")
    #:keymap 'flypy
    #:legends '(abc flypy)
    (rime #:source "flypy"
          #:config "flypy"
          #:generated? #t
          #:custom? #t)
    (layout "double-pinyin-flypy"
      #:skin "flypy"
      #:placement 'split-flypy)
    (layout "double-pinyin-flypy-14"
      #:keyboard 'compact-14
      #:skin "flypy-14"
      #:placement 'compact-center
      #:name '("Flypy 14" "小鶴雙拼 14鍵")
      #:description '("A 14-key Flypy double pinyin input method for Yuanshu, grouping adjacent QWERTY keys."
                      "14 鍵小鶴元書輸入法，按相鄰 QWERTY 鍵位分組。")
      #:rime-source "flypy-14")
    (layout "double-pinyin-flypy-18"
      #:keyboard 'compact-18
      #:skin "flypy-18"
      #:placement 'compact-center
      #:name '("Flypy 18" "小鶴雙拼 18鍵")
      #:description '("An 18-key Flypy double pinyin input method for Yuanshu, adapted from a compact phone layout."
                      "18 鍵小鶴元書輸入法，改編自緊湊手機鍵盤佈局。")
      #:rime-source "flypy-18")
    (layout "double-pinyin-flypy-shuffle-17"
      #:keyboard 'shuffle-17
      #:skin "shuffle-17"
      #:placement 'compact-center
      #:name '("Flypy Shuffle 17" "小鶴雙拼亂序 17鍵")
      #:description '("An experimental 17-key shuffled Flypy input method for Yuanshu."
                      "實驗性的 17 鍵亂序小鶴元書輸入法。")
      #:rime-source "shuffle-17"))

  (input-method "luna-pinyin"
    #:category "full-pinyin"
    #:name '("Luna Pinyin" "朙月拼音")
    #:description '("Standard full-pinyin Mandarin input, available as both Rime config and Yuanshu package."
                    "標準全拼普通話輸入方案，可輸出 Rime 設定與元書套件。")
    #:keymap 'abc
    #:legends '(abc)
    (rime #:source "luna-pinyin" #:generated? #t)
    (layout "luna-pinyin"
      #:skin "luna-pinyin")
    (layout "pinyin-14"
      #:keyboard 'compact-14
      #:skin "pinyin-14"
      #:placement 'compact-center
      #:name '("Pinyin 14-Key" "朙月拼音-14鍵")
      #:description '("A 14-key full-pinyin Yuanshu input method using adjacent QWERTY groups."
                      "14 鍵全拼元書輸入法，使用相鄰 QWERTY 分組。")
      #:rime-source "pinyin-14"))

  (input-method "terra-pinyin"
    #:category "full-pinyin"
    #:name '("Terra Pinyin" "地球拼音")
    #:description '("Full-pinyin Mandarin input with tone-number support and matching Yuanshu layout previews."
                    "支援聲調數字的全拼普通話輸入，並提供元書鍵盤佈局預覽。")
    #:keymap 'abc
    #:legends '(abc)
    (rime #:source "terra-pinyin" #:generated? #t)
    (layout "terra-pinyin"
      #:skin "terra-pinyin"))

  (input-method "cangjie6"
    #:category "shape"
    #:name '("Cangjie 6" "蒼頡六代")
    #:description '("Sixth-generation Cangjie shape input with Rime config and Yuanshu keyboard layout support."
                    "第六代蒼頡字形輸入，提供 Rime 設定與元書鍵盤佈局。")
    #:keymap 'cangjie
    #:legends '(cangjie)
    (rime #:generated? #t
          #:custom? #t
          #:deps '("double-pinyin-flypy"))
    (layout "cangjie6"
      #:skin "cangjie6"))

  (input-method "cangjie5"
    #:method-schema "cangjie6"
    #:category "shape"
    #:name '("Cangjie 5" "倉頡五代")
    #:description '("Upstream Rime fifth-generation Cangjie shape input."
                    "上游 Rime 第五代倉頡字形輸入方案。")
    #:keymap 'cangjie
    #:legends '(cangjie)
    (rime #:deps '("luna-pinyin")
          #:extra-files '("cangjie5.dict.yaml"))
    (layout "cangjie5"
      #:skin "cangjie6"))

  (input-method "cangjie5-express"
    #:method-schema "cangjie6"
    #:category "shape"
    #:name '("Cangjie 5 Express" "倉頡五代·快打模式")
    #:description '("Upstream Rime Cangjie 5 schema with express auto-selection behavior."
                    "上游 Rime 倉頡五代快打模式方案。")
    #:keymap 'cangjie
    #:legends '(cangjie)
    (rime #:source "cangjie5-express"
          #:deps '("luna-pinyin")
          #:extra-files '("cangjie5.dict.yaml"))
    (layout "cangjie5-express"
      #:skin "cangjie6"))

  (input-method "quick5"
    #:method-schema "cangjie6"
    #:category "shape"
    #:name '("Quick 5" "速成")
    #:description '("Upstream Rime Quick 5 shape input derived from Cangjie."
                    "上游 Rime 速成五代字形輸入方案。")
    #:keymap 'cangjie
    #:legends '(cangjie)
    (rime #:deps '("luna-pinyin")
          #:extra-files '("quick5.dict.yaml"))
    (layout "quick5"
      #:skin "cangjie6"))

  (input-method "jyut6ping3"
    #:category "full-pinyin"
    #:name '("Jyutping" "粵拼")
    #:description '("Jyutping Cantonese input with Cantonese dictionaries and Yuanshu keyboard layout support."
                    "香港語言學會粵拼輸入，包含粵語詞庫與元書鍵盤佈局。")
    #:keymap 'jyutping
    #:legends '(abc jyutping)
    (rime #:generated? #t
          #:custom? #t
          #:deps '("double-pinyin-flypy" "cangjie6"))
    (layout "jyut6ping3"
      #:skin "jyut6ping3"
      #:placement 'standard-top-center))

  (input-method "bopomofo"
    #:category "zhuyin"
    #:name '("Zhuyin" "注音")
    #:description '("Zhuyin input for Mandarin, arranged for standard and Yuanshu keyboard layouts."
                    "注音符號普通話輸入，配置為元書鍵盤佈局。")
    #:keymap 'zhuyin
    #:legends '(zhuyin)
    (layout "bopomofo-standard"
      #:keyboard 'standard-zhuyin
      #:skin "bopomofo-standard"
      #:name '("Bopomofo Standard" "標準注音")
      #:description '("Zhuyin input on the standard Da-Chien physical keyboard."
                      "使用標準大千式實體鍵盤排列的注音輸入法。")
      #:rime-source "bopomofo-standard"
      #:rime-config "bopomofo"
      #:rime-extra-files '("terra_pinyin.dict.yaml" "zhuyin.yaml")
      #:rime-artifacts '("rime"))
    (layout "bopomofo"
      #:keyboard 'zhuyin
      #:skin "bopomofo"
      #:name '("Ortholinear Bopomofo" "正交注音")
      #:description '("Zhuyin input arranged on an ortholinear mobile keyboard."
                      "配置為正交手機鍵盤的注音輸入法。")
      #:rime-generated? #t
      #:rime-artifacts '("yuanshu")))

  (input-method "double-pinyin"
    #:slug "double-pinyin-zrm"
    #:category "double-pinyin"
    #:name '("Double Pinyin: ZRM" "自然碼雙拼")
    #:description '("Upstream Rime double-pinyin schema using the Ziranma layout."
                    "上游 Rime 自然碼雙拼方案。")
    #:keymap 'zrm
    #:legends '(abc zrm)
    (rime #:source "double-pinyin" #:deps '("stroke"))
    (layout "double-pinyin"
      #:skin "double-pinyin-zrm"
      #:placement 'double-pinyin-center))

  (input-method "double-pinyin-abc"
    #:category "double-pinyin"
    #:name '("Double Pinyin: ABC" "智能ABC雙拼")
    #:description '("Upstream Rime double-pinyin schema using the Intelligent ABC layout."
                    "上游 Rime 智能 ABC 雙拼方案。")
    #:keymap 'abc-dp
    #:legends '(abc abc-dp)
    (rime #:source "double-pinyin-abc" #:deps '("stroke"))
    (layout "double-pinyin-abc"
      #:skin "double-pinyin-abc"
      #:placement 'double-pinyin-center))

  (input-method "double-pinyin-mspy"
    #:category "double-pinyin"
    #:name '("Double Pinyin: MSPY" "微軟雙拼")
    #:description '("Upstream Rime double-pinyin schema using the Microsoft layout."
                    "上游 Rime 微軟雙拼方案。")
    #:keymap 'mspy
    #:legends '(abc mspy)
    (rime #:source "double-pinyin-mspy" #:deps '("stroke"))
    (layout "double-pinyin-mspy"
      #:skin "double-pinyin-mspy"
      #:placement 'double-pinyin-center))

  (input-method "double-pinyin-pyjj"
    #:category "double-pinyin"
    #:name '("Double Pinyin: PYJJ" "拼音加加雙拼")
    #:description '("Upstream Rime double-pinyin schema using the Pinyin Jiajia layout."
                    "上游 Rime 拼音加加雙拼方案。")
    #:keymap 'pyjj
    #:legends '(abc pyjj)
    (rime #:source "double-pinyin-pyjj" #:deps '("stroke"))
    (layout "double-pinyin-pyjj"
      #:skin "double-pinyin-pyjj"
      #:placement 'double-pinyin-center))

  (input-method "double-pinyin-st"
    #:category "double-pinyin"
    #:name '("Double Pinyin: ST" "四通雙拼")
    #:description '("Upstream Rime double-pinyin schema using the Stone layout."
                    "上游 Rime 四通雙拼方案。")
    #:keymap 'st
    #:legends '(abc st)
    (rime #:source "double-pinyin-st" #:deps '("stroke"))
    (layout "double-pinyin-st"
      #:skin "double-pinyin-st"
      #:placement 'double-pinyin-center))

  (input-method "wubi86"
    #:category "shape"
    #:name '("Wubi 86" "五筆86")
    #:description '("Upstream Rime Wubi 86 shape input."
                    "上游 Rime 五筆 86 字形輸入方案。")
    #:keymap 'wubi
    #:legends '(abc wubi)
    (rime #:deps '("pinyin-simp") #:extra-files '("wubi86.dict.yaml"))
    (layout "wubi86"
      #:skin "wubi86"
      #:placement 'standard-top-center))

  (input-method "wubi-pinyin"
    #:method-schema "wubi86"
    #:category "shape"
    #:name '("Wubi Pinyin" "五筆·拼音")
    #:description '("Upstream Rime Wubi schema with pinyin mixed input."
                    "上游 Rime 五筆拼音混輸方案。")
    #:keymap 'wubi
    #:legends '(abc wubi)
    (rime #:source "wubi-pinyin"
          #:deps '("pinyin-simp")
          #:extra-files '("wubi86.dict.yaml"))
    (layout "wubi-pinyin"
      #:skin "wubi86"
      #:placement 'standard-top-center))

  (input-method "wubi-trad"
    #:method-schema "wubi86"
    #:category "shape"
    #:name '("Wubi Traditional" "五筆·簡入繁出")
    #:description '("Upstream Rime Wubi schema for simplified input with traditional output."
                    "上游 Rime 五筆簡入繁出方案。")
    #:keymap 'wubi
    #:legends '(abc wubi)
    (rime #:source "wubi-trad"
          #:deps '("pinyin-simp")
          #:extra-files '("wubi86.dict.yaml"))
    (layout "wubi-trad"
      #:skin "wubi86"
      #:placement 'standard-top-center))

  (input-method "stroke"
    #:category "shape"
    #:name '("Stroke" "五筆畫")
    #:description '("Supporting five-stroke lookup schema used by upstream double-pinyin and Wubi packages."
                    "上游雙拼與五筆方案使用的五筆畫反查支援方案。")
    #:keymap 'stroke
    #:legends '(abc stroke)
    (rime #:deps '("luna-pinyin") #:extra-files '("stroke.dict.yaml"))
    (layout "stroke"
      #:skin "stroke"
      #:placement 'standard-top-center))

  (input-method "pinyin-simp"
    #:method-schema "luna-pinyin"
    #:category "full-pinyin"
    #:name '("Pinyin Simplified" "袖珍簡化字拼音")
    #:description '("Supporting simplified pinyin schema used by upstream Wubi packages."
                    "上游五筆方案使用的簡化字拼音反查支援方案。")
    #:keymap 'abc
    #:legends '(abc)
    (rime #:source "pinyin-simp"
          #:deps '("stroke")
          #:extra-files '("pinyin_simp.dict.yaml"))
    (layout "pinyin-simp"
      #:skin "luna-pinyin")))
