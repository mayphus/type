#lang s-exp "../../lang/rime.rkt"

(rime-schema flypy_9
  (name "小鶴雙拼 9鍵")
  (artifacts yuanshu)
  (keyboard flypy_9
    (model compact-9)
    (meta
     (name "Flypy 9 Key" "小鶴雙拼 9鍵")
     (summary "A compact Yuanshu keyboard layout for the Flypy 9-key layout.")
     (features
      "9-key phone layout"
      "Standard iPad pinyin page and secondary pages"))
    (variant flypy-9)
    (print flypy center)
    (ipad standard-18))
  (deps cangjie6)
  (schema
   (version "0.1")
   (authors
    "double pinyin layout by 鶴"
    "9-key QWERTY row merge layout adapted in this workspace")
   (description
    "朙月拼音＋小鶴雙拼 9 鍵方案。\niPhone 佈局按 QWERTY 行分組：\nQWE / RTY / UIOP\nASD / FGH / JKL\nZXC / VBN / M")
   (switches
    (switch 'ascii_mode #:reset 0 #:states '("9鍵" "A"))
    (switch 'simplification #:states '("漢字" "汉字"))
    (switch 'full_shape #:states '("半角" "全角"))
    (switch 'ascii_punct #:states '("。，" "．，")))
   (engine
    #:translators '(punct_translator reverse_lookup_translator script_translator))
   (speller
    #:alphabet "qruafjzvm"
    #:delimiter " '"
    #:algebra
    '("erase/^xx$/"
      "derive/^([jqxy])u$/$1v/"
      "derive/^([aoe])([ioun])$/$1$1$2/"
      "xform/^([aoe])(ng)?$/$1$1$2/"
      "xform/iu$/Q/"
      "xform/(.)ei$/$1W/"
      "xform/uan$/R/"
      "xform/[uv]e$/T/"
      "xform/un$/Y/"
      "xform/^sh/U/"
      "xform/^ch/I/"
      "xform/^zh/V/"
      "xform/uo$/O/"
      "xform/ie$/P/"
      "xform/i?ong$/S/"
      "xform/ing$|uai$/K/"
      "xform/(.)ai$/$1D/"
      "xform/(.)en$/$1F/"
      "xform/(.)eng$/$1G/"
      "xform/[iu]ang$/L/"
      "xform/(.)ang$/$1H/"
      "xform/ian$/M/"
      "xform/(.)an$/$1J/"
      "xform/(.)ou$/$1Z/"
      "xform/[iu]a$/X/"
      "xform/iao$/N/"
      "xform/(.)ao$/$1C/"
      "xform/ui$/V/"
      "xform/in$/B/"
      "xform/([A-Z])/$1/"
      "xlit/QWERTYUIOPASDFGHJKLZXCVBNM/qwertyuiopasdfghjklzxcvbnm/"
      "xlit/qwertyuiopasdfghjklzxcvbnm/qqqrrruuuuaaafffjjjzzzvvvm/"))
   (translator #:dictionary 'luna_pinyin #:prism 'flypy_9)
   (reverse-lookup
    #:dictionary 'cangjie6
    #:prefix "`"
    #:suffix "'"
    #:tips "〔蒼頡〕"
    #:preedit-format
    '("xlit|abcdefghijklmnopqrstuvwxyz|日月金木水火土的戈十大中一弓人心手口尸廿山女田止卜片|")
    #:comment-format
    '("xlit|abcdefghijklmnopqrstuvwxyz|日月金木水火土的戈十大中一弓人心手口尸廿山女田止卜片|"))
   (preset-section 'punctuator)
   (preset-section 'key_binder)
   (recognizer
    #:patterns
    (list (pattern 'reverse_lookup "`[a-z]*'?$"))))
  (custom "flypy_9.custom.yaml"
    (includes yuanshu_common_patch yuanshu_reverse_lookup_patch)
   (version "0.1")
   (description
     "朙月拼音＋小鶴雙拼 9 鍵方案。\n使用預設詞庫，適合 Yuanshu iPhone 9 鍵圖示皮膚。")))
