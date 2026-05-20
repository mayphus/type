#lang racket/base

(require "lang/type.rkt")

(provide type-catalog)

(define-type-catalog type-catalog
   (schema "double-pinyin-flypy"
           #:category "double-pinyin"
           #:name '("Flypy" "小鶴雙拼")
           #:description '("Flypy double pinyin with Rime config and Yuanshu keyboard layout previews."
                           "小鶴方案，提供 Rime 設定與元書鍵盤佈局預覽。"))
   (schema "luna-pinyin"
           #:category "full-pinyin"
           #:name '("Luna Pinyin" "朙月拼音")
           #:description '("Standard full-pinyin Mandarin input, available as both Rime config and Yuanshu package."
                           "標準全拼普通話輸入方案，可輸出 Rime 設定與元書套件。"))
   (schema "terra-pinyin"
           #:category "full-pinyin"
           #:name '("Terra Pinyin" "地球拼音")
           #:description '("Full-pinyin Mandarin input with tone-number support and matching Yuanshu layout previews."
                           "支援聲調數字的全拼普通話輸入，並提供元書鍵盤佈局預覽。"))
   (schema "double-pinyin"
           #:slug "double-pinyin-zrm"
           #:category "double-pinyin"
           #:name '("Double Pinyin: ZRM" "自然碼雙拼")
           #:description '("Upstream Rime double-pinyin schema using the Ziranma layout."
                           "上游 Rime 自然碼雙拼方案。"))
   (schema "double-pinyin-abc"
           #:slug "double-pinyin-abc"
           #:category "double-pinyin"
           #:name '("Double Pinyin: ABC" "智能ABC雙拼")
           #:description '("Upstream Rime double-pinyin schema using the Intelligent ABC layout."
                           "上游 Rime 智能 ABC 雙拼方案。"))
   (schema "double-pinyin-mspy"
           #:slug "double-pinyin-mspy"
           #:category "double-pinyin"
           #:name '("Double Pinyin: MSPY" "微軟雙拼")
           #:description '("Upstream Rime double-pinyin schema using the Microsoft layout."
                           "上游 Rime 微軟雙拼方案。"))
   (schema "double-pinyin-pyjj"
           #:slug "double-pinyin-pyjj"
           #:category "double-pinyin"
           #:name '("Double Pinyin: PYJJ" "拼音加加雙拼")
           #:description '("Upstream Rime double-pinyin schema using the Pinyin Jiajia layout."
                           "上游 Rime 拼音加加雙拼方案。"))
   (schema "double-pinyin-st"
           #:slug "double-pinyin-st"
           #:category "double-pinyin"
           #:name '("Double Pinyin: ST" "四通雙拼")
           #:description '("Upstream Rime double-pinyin schema using the Stone layout."
                           "上游 Rime 四通雙拼方案。"))
   (schema "cangjie5"
           #:category "shape"
           #:name '("Cangjie 5" "倉頡五代")
           #:description '("Upstream Rime fifth-generation Cangjie shape input."
                           "上游 Rime 第五代倉頡字形輸入方案。"))
   (schema "cangjie5-express"
           #:category "shape"
           #:name '("Cangjie 5 Express" "倉頡五代·快打模式")
           #:description '("Upstream Rime Cangjie 5 schema with express auto-selection behavior."
                           "上游 Rime 倉頡五代快打模式方案。"))
   (schema "cangjie6"
           #:category "shape"
           #:name '("Cangjie 6" "蒼頡六代")
           #:description '("Sixth-generation Cangjie shape input with Rime config and Yuanshu keyboard layout support."
                           "第六代蒼頡字形輸入，提供 Rime 設定與元書鍵盤佈局。"))
   (schema "wubi86"
           #:category "shape"
           #:name '("Wubi 86" "五筆86")
           #:description '("Upstream Rime Wubi 86 shape input."
                           "上游 Rime 五筆 86 字形輸入方案。"))
   (schema "wubi-pinyin"
           #:category "shape"
           #:name '("Wubi Pinyin" "五筆·拼音")
           #:description '("Upstream Rime Wubi schema with pinyin mixed input."
                           "上游 Rime 五筆拼音混輸方案。"))
   (schema "wubi-trad"
           #:category "shape"
           #:name '("Wubi Traditional" "五筆·簡入繁出")
           #:description '("Upstream Rime Wubi schema for simplified input with traditional output."
                           "上游 Rime 五筆簡入繁出方案。"))
   (schema "quick5"
           #:category "shape"
           #:name '("Quick 5" "速成")
           #:description '("Upstream Rime Quick 5 shape input derived from Cangjie."
                           "上游 Rime 速成五代字形輸入方案。"))
   (schema "stroke"
           #:category "shape"
           #:name '("Stroke" "五筆畫")
           #:description '("Supporting five-stroke lookup schema used by upstream double-pinyin and Wubi packages."
                           "上游雙拼與五筆方案使用的五筆畫反查支援方案。"))
   (schema "pinyin-simp"
           #:category "full-pinyin"
           #:name '("Pinyin Simplified" "袖珍簡化字拼音")
           #:description '("Supporting simplified pinyin schema used by upstream Wubi packages."
                           "上游五筆方案使用的簡化字拼音反查支援方案。"))
   (schema "jyut6ping3"
           #:category "full-pinyin"
           #:name '("Jyutping" "粵拼")
           #:description '("Jyutping Cantonese input with Cantonese dictionaries and Yuanshu keyboard layout support."
                           "香港語言學會粵拼輸入，包含粵語詞庫與元書鍵盤佈局。"))
   (schema "bopomofo"
           #:category "zhuyin"
           #:name '("Zhuyin" "注音")
           #:description '("Zhuyin input for Mandarin, arranged for standard and Yuanshu keyboard layouts."
                           "注音符號普通話輸入，配置為元書鍵盤佈局。"))

   (method "double-pinyin-flypy"
           #:schema "double-pinyin-flypy"
           #:keymap 'flypy
           #:legends '(abc flypy)
           #:keyboards
           (list
            (keyboard "double-pinyin-flypy" 'standard-26 "flypy" 'split-flypy
                      #:rime-source-id "flypy"
                      #:rime-config-id "flypy"
                      #:rime-generated? #t
                      #:rime-custom? #t)
            (keyboard "double-pinyin-flypy-14" 'compact-14 "flypy_14" 'compact-center
                      #:name '("Flypy 14" "小鶴雙拼 14鍵")
                      #:description '("A 14-key Flypy double pinyin input method for Yuanshu, grouping adjacent QWERTY keys."
                                      "14 鍵小鶴元書輸入法，按相鄰 QWERTY 鍵位分組。")
                      #:rime-source-id "flypy_14"
                      #:rime-generated? #t)
            (keyboard "double-pinyin-flypy-18" 'compact-18 "flypy_18" 'compact-center
                      #:name '("Flypy 18" "小鶴雙拼 18鍵")
                      #:description '("An 18-key Flypy double pinyin input method for Yuanshu, adapted from a compact phone layout."
                                      "18 鍵小鶴元書輸入法，改編自緊湊手機鍵盤佈局。")
                      #:rime-source-id "flypy_18"
                      #:rime-generated? #t)
            (keyboard "double-pinyin-flypy-shuffle-17" 'shuffle-17 "shuffle_17" 'compact-center
                      #:name '("Flypy Shuffle 17" "小鶴雙拼亂序 17鍵")
                      #:description '("An experimental 17-key shuffled Flypy input method for Yuanshu."
                                      "實驗性的 17 鍵亂序小鶴元書輸入法。")
                      #:rime-source-id "shuffle_17"
                      #:rime-generated? #t)))
   (method "luna-pinyin"
           #:schema "luna-pinyin"
           #:keymap 'abc
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "luna-pinyin" 'standard-26 "luna_pinyin" 'standard-center
                      #:rime-source-id "luna_pinyin"
                      #:rime-generated? #t)
            (keyboard "pinyin-14" 'compact-14 "pinyin_14" 'compact-center
                      #:name '("Pinyin 14-Key" "朙月拼音-14鍵")
                      #:description '("A 14-key full-pinyin Yuanshu input method using adjacent QWERTY groups."
                                      "14 鍵全拼元書輸入法，使用相鄰 QWERTY 分組。")
                      #:rime-source-id "pinyin_14"
                      #:rime-generated? #t)))
   (method "terra-pinyin"
           #:schema "terra-pinyin"
           #:keymap 'abc
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "terra-pinyin" 'standard-26 "terra_pinyin" 'standard-center
                      #:rime-source-id "terra_pinyin"
                      #:rime-generated? #t)))
   (method "cangjie6"
           #:keymap 'cangjie
           #:legends '(cangjie)
           #:keyboards
           (list
            (keyboard "cangjie6" 'standard-26 "cangjie6" 'standard-center
                      #:rime-generated? #t
                      #:rime-custom? #t
                      #:rime-deps '("double-pinyin-flypy"))
            (keyboard "cangjie5" 'standard-26 "cangjie6" 'standard-center
                      #:rime-deps '("luna-pinyin")
                      #:rime-extra-files '("cangjie5.dict.yaml"))
            (keyboard "cangjie5-express" 'standard-26 "cangjie6" 'standard-center
                      #:rime-source-id "cangjie5_express"
                      #:rime-deps '("luna-pinyin")
                      #:rime-extra-files '("cangjie5.dict.yaml"))
            (keyboard "quick5" 'standard-26 "cangjie6" 'standard-center
                      #:rime-deps '("luna-pinyin")
                      #:rime-extra-files '("quick5.dict.yaml"))))
   (method "jyut6ping3"
           #:keymap 'jyutping
           #:legends '(abc jyutping)
           #:keyboards
           (list
            (keyboard "jyut6ping3" 'standard-26 "jyut6ping3" 'standard-top-center
                      #:rime-generated? #t
                      #:rime-custom? #t
                      #:rime-deps '("double-pinyin-flypy" "cangjie6"))))
   (method "bopomofo"
           #:keymap 'zhuyin
           #:legends '(zhuyin)
           #:keyboards
           (list
            (keyboard "bopomofo-standard" 'standard-zhuyin "bopomofo_standard" 'standard-center
                      #:name '("Bopomofo Standard" "標準注音")
                      #:description '("Zhuyin input on the standard Da-Chien physical keyboard."
                                      "使用標準大千式實體鍵盤排列的注音輸入法。")
                      #:rime-source-id "bopomofo-standard"
                      #:rime-config-id "bopomofo"
                      #:rime-extra-files '("terra_pinyin.dict.yaml" "zhuyin.yaml")
                      #:rime-artifacts '("rime"))
            (keyboard "bopomofo" 'zhuyin "bopomofo" 'standard-center
                      #:name '("Ortholinear Bopomofo" "正交注音")
                      #:description '("Zhuyin input arranged on an ortholinear mobile keyboard."
                                      "配置為正交手機鍵盤的注音輸入法。")
                      #:rime-generated? #t
                      #:rime-artifacts '("yuanshu"))))
   (method "double-pinyin"
           #:schema "double-pinyin"
           #:keymap 'zrm
           #:legends '(abc zrm)
           #:keyboards
           (list
            (keyboard "double-pinyin" 'standard-26 "double_pinyin_zrm" 'double-pinyin-center
                      #:rime-source-id "double_pinyin"
                      #:rime-deps '("stroke"))))
   (method "double-pinyin-abc"
           #:schema "double-pinyin-abc"
           #:keymap 'abc-dp
           #:legends '(abc abc-dp)
           #:keyboards
           (list
            (keyboard "double-pinyin-abc" 'standard-26 "double_pinyin_abc" 'double-pinyin-center
                      #:rime-source-id "double_pinyin_abc"
                      #:rime-deps '("stroke"))))
   (method "double-pinyin-mspy"
           #:schema "double-pinyin-mspy"
           #:keymap 'mspy
           #:legends '(abc mspy)
           #:keyboards
           (list
            (keyboard "double-pinyin-mspy" 'standard-26 "double_pinyin_mspy" 'double-pinyin-center
                      #:rime-source-id "double_pinyin_mspy"
                      #:rime-deps '("stroke"))))
   (method "double-pinyin-pyjj"
           #:schema "double-pinyin-pyjj"
           #:keymap 'pyjj
           #:legends '(abc pyjj)
           #:keyboards
           (list
            (keyboard "double-pinyin-pyjj" 'standard-26 "double_pinyin_pyjj" 'double-pinyin-center
                      #:rime-source-id "double_pinyin_pyjj"
                      #:rime-deps '("stroke"))))
   (method "double-pinyin-st"
           #:schema "double-pinyin-st"
           #:keymap 'st
           #:legends '(abc st)
           #:keyboards
           (list
            (keyboard "double-pinyin-st" 'standard-26 "double_pinyin_st" 'double-pinyin-center
                      #:rime-source-id "double_pinyin_st"
                      #:rime-deps '("stroke"))))
   (method "wubi86"
           #:keymap 'wubi
           #:legends '(abc wubi)
           #:keyboards
           (list
            (keyboard "wubi86" 'standard-26 "wubi86" 'standard-top-center
                      #:rime-deps '("pinyin-simp")
                      #:rime-extra-files '("wubi86.dict.yaml"))
            (keyboard "wubi-pinyin" 'standard-26 "wubi86" 'standard-top-center
                      #:rime-source-id "wubi_pinyin"
                      #:rime-deps '("pinyin-simp")
                      #:rime-extra-files '("wubi86.dict.yaml"))
            (keyboard "wubi-trad" 'standard-26 "wubi86" 'standard-top-center
                      #:rime-source-id "wubi_trad"
                      #:rime-deps '("pinyin-simp")
                      #:rime-extra-files '("wubi86.dict.yaml"))))
   (method "stroke"
           #:keymap 'stroke
           #:legends '(abc stroke)
           #:keyboards
           (list
            (keyboard "stroke" 'standard-26 "stroke" 'standard-top-center
                      #:rime-deps '("luna-pinyin")
                      #:rime-extra-files '("stroke.dict.yaml"))))
   (method "pinyin-simp"
           #:schema "luna-pinyin"
           #:keymap 'abc
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "pinyin-simp" 'standard-26 "luna_pinyin" 'standard-center
                      #:rime-source-id "pinyin_simp"
                      #:rime-deps '("stroke")
                      #:rime-extra-files '("pinyin_simp.dict.yaml")))))
