#lang racket/base

(require "lang/type.rkt")

(provide input-methods)

(define-input-methods input-methods
  (input-family #:category "double-pinyin"
                #:placement 'double-pinyin-center
                #:rime-deps '("stroke")
    (family-layout "-14"
      #:keyboard 'compact-14
      #:placement 'compact-center
      #:rime-source-suffix "-14")
    (family-layout "-shuffle-17"
      #:keyboard 'shuffle-17
      #:generated-skin "shuffle-17"
      #:placement 'compact-center
      #:rime-source "shuffle-17")
    (family-layout "-18"
      #:keyboard 'compact-18
      #:placement 'compact-center
      #:rime-source-suffix "-18")

    (input-method "double-pinyin-flypy"
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
        #:placement 'split-flypy))

    (input-method "double-pinyin"
      #:slug "double-pinyin-zrm"
      #:name '("Double Pinyin: ZRM" "自然碼雙拼")
      #:description '("Upstream Rime double-pinyin schema using the Ziranma layout."
                      "上游 Rime 自然碼雙拼方案。")
      #:keymap 'zrm
      #:legends '(abc zrm)
      (rime #:source "double-pinyin")
      (layout "double-pinyin"
        #:skin "double-pinyin-zrm"))

    (input-method "double-pinyin-abc"
      #:name '("Double Pinyin: ABC" "智能ABC雙拼")
      #:description '("Upstream Rime double-pinyin schema using the Intelligent ABC layout."
                      "上游 Rime 智能 ABC 雙拼方案。")
      #:keymap 'abc-dp
      #:legends '(abc abc-dp)
      (rime #:source "double-pinyin-abc")
      (layout "double-pinyin-abc"))

    (input-method "double-pinyin-mspy"
      #:name '("Double Pinyin: MSPY" "微軟雙拼")
      #:description '("Upstream Rime double-pinyin schema using the Microsoft layout."
                      "上游 Rime 微軟雙拼方案。")
      #:keymap 'mspy
      #:legends '(abc mspy)
      (rime #:source "double-pinyin-mspy")
      (layout "double-pinyin-mspy"))

    (input-method "double-pinyin-pyjj"
      #:name '("Double Pinyin: PYJJ" "拼音加加雙拼")
      #:description '("Upstream Rime double-pinyin schema using the Pinyin Jiajia layout."
                      "上游 Rime 拼音加加雙拼方案。")
      #:keymap 'pyjj
      #:legends '(abc pyjj)
      (rime #:source "double-pinyin-pyjj")
      (layout "double-pinyin-pyjj"))

    (input-method "double-pinyin-st"
      #:name '("Double Pinyin: ST" "四通雙拼")
      #:description '("Upstream Rime double-pinyin schema using the Stone layout."
                      "上游 Rime 四通雙拼方案。")
      #:keymap 'st
      #:legends '(abc st)
      (rime #:source "double-pinyin-st")
      (layout "double-pinyin-st")))

  (input-method "luna-pinyin"
    #:category "full-pinyin"
    #:name '("Luna Pinyin" "朙月拼音")
    #:description '("Standard full-pinyin Mandarin input, available as both Rime config and Yuanshu package."
                    "標準全拼普通話輸入方案，可輸出 Rime 設定與元書套件。")
    #:keymap 'abc
    #:legends '(abc)
    (rime #:source "luna-pinyin" #:generated? #t)
    (layout "luna-pinyin")
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
    (layout "terra-pinyin"))

  (input-family #:category "shape"
                #:method-schema "cangjie6"
                #:rime-deps '("luna-pinyin")
    (input-method "cangjie6"
      #:name '("Cangjie 6" "蒼頡六代")
      #:description '("Sixth-generation Cangjie shape input with Rime config and Yuanshu keyboard layout support."
                      "第六代蒼頡字形輸入，提供 Rime 設定與元書鍵盤佈局。")
      #:keymap 'cangjie6
      #:legends '(cangjie6)
      (rime #:generated? #t
            #:custom? #t
            #:deps '("double-pinyin-flypy"))
      (layout "cangjie6"))

    (input-method "cangjie5"
      #:name '("Cangjie 5" "倉頡五代")
      #:description '("Upstream Rime fifth-generation Cangjie shape input."
                      "上游 Rime 第五代倉頡字形輸入方案。")
      #:keymap 'cangjie5
      #:legends '(cangjie5)
      (rime #:extra-files '("cangjie5.dict.yaml"))
      (layout "cangjie5"))

    (input-method "cangjie5-express"
      #:name '("Cangjie 5 Express" "倉頡五代·快打模式")
      #:description '("Upstream Rime Cangjie 5 schema with express auto-selection behavior."
                      "上游 Rime 倉頡五代快打模式方案。")
      #:keymap 'cangjie5
      #:legends '(cangjie5)
      (rime #:source "cangjie5-express"
            #:extra-files '("cangjie5.dict.yaml"))
      (layout "cangjie5-express" #:skin "cangjie5"))

    (input-method "quick5"
      #:name '("Quick 5" "速成")
      #:description '("Upstream Rime Quick 5 shape input derived from Cangjie."
                      "上游 Rime 速成五代字形輸入方案。")
      #:keymap 'cangjie5
      #:legends '(cangjie5)
      (rime #:extra-files '("quick5.dict.yaml"))
      (layout "quick5" #:skin "cangjie5")))

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
      #:name '("Ortholinear Bopomofo" "正交注音")
      #:description '("Zhuyin input arranged on an ortholinear mobile keyboard."
                      "配置為正交手機鍵盤的注音輸入法。")
      #:rime-generated? #t
      #:rime-artifacts '("yuanshu")))

  (input-family #:category "shape"
                #:method-schema "wubi86"
                #:keymap 'wubi
                #:legends '(abc wubi)
                #:placement 'standard-top-center
                #:rime-deps '("pinyin-simp")
                #:rime-extra-files '("wubi86.dict.yaml")
    (input-method "wubi86"
      #:name '("Wubi 86" "五筆86")
      #:description '("Upstream Rime Wubi 86 shape input."
                      "上游 Rime 五筆 86 字形輸入方案。")
      (layout "wubi86"))

    (input-method "wubi-pinyin"
      #:name '("Wubi Pinyin" "五筆·拼音")
      #:description '("Upstream Rime Wubi schema with pinyin mixed input."
                      "上游 Rime 五筆拼音混輸方案。")
      (rime #:source "wubi-pinyin")
      (layout "wubi-pinyin"
        #:skin "wubi86"))

    (input-method "wubi-trad"
      #:name '("Wubi Traditional" "五筆·簡入繁出")
      #:description '("Upstream Rime Wubi schema for simplified input with traditional output."
                      "上游 Rime 五筆簡入繁出方案。")
      (rime #:source "wubi-trad")
      (layout "wubi-trad"
        #:skin "wubi86")))

  (support-schema "stroke"
    #:name '("Stroke" "五筆畫")
    #:description '("Supporting five-stroke lookup schema used by upstream double-pinyin and Wubi packages."
                    "上游雙拼與五筆方案使用的五筆畫反查支援方案。")
    #:rime-deps '("luna-pinyin")
    #:extra-files '("stroke.dict.yaml"))

  (support-schema "pinyin-simp"
    #:source "pinyin-simp"
    #:name '("Pinyin Simplified" "袖珍簡化字拼音")
    #:description '("Supporting simplified pinyin schema used by upstream Wubi packages."
                    "上游五筆方案使用的簡化字拼音反查支援方案。")
    #:rime-deps '("stroke")
    #:extra-files '("pinyin_simp.dict.yaml")))
