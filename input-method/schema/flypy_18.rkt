#lang s-exp "lib/lang.rkt"

(rime-schema flypy_18
  (name "小鶴雙拼-18鍵")
  (artifacts yuanshu)
  (keyboard flypy_18
    (model compact-18)
    (meta
     (name "Flypy-18 Key" "小鶴-18鍵")
     (summary "A compact Yuanshu keyboard layout for the Flypy 18-key layout.")
     (features
      "18-key phone layout"
      "Standard iPad pinyin page and secondary pages"))
    (variant flypy-18)
    (print flypy center)
    (ipad standard-18))
  (deps cangjie6)
  (static-files "rime_ice.dict.yaml")
  (static-dirs "rime_ice_dicts")
  (schema
   (version "0.1")
   (authors
    "double pinyin layout by 鶴"
    "screenshot-based 18-key merge layout adapted in this workspace"
    "dictionary import from iDvel/rime-ice")
   (description
    "朙月拼音＋小鶴雙拼 18 鍵方案，使用 rime-ice 詞庫。\niPhone 佈局參照圖片分組：\nQ / WE / RT / Y / U / IO / P\nA / SD / FG / H / JK / L\nZ / XC / V / BN / M")
   (switches
    (switch 'ascii_mode #:reset 0 #:states '("18鍵" "A"))
    (switch 'simplification #:states '("漢字" "汉字"))
    (switch 'full_shape #:states '("半角" "全角"))
    (switch 'ascii_punct #:states '("。，" "．，")))
   (engine
    #:translators '(punct_translator reverse_lookup_translator script_translator))
   (speller
    #:alphabet "qwryuipasfhjlzxvbm"
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
      "xlit/QWRTYUIOPSDFGHJKLZXCVBNM/qwrtyuiopsdfghjklzxcvbnm/"
      "xlit/etodgkcn/wrisfjxb/"))
   (translator #:dictionary 'rime_ice #:prism 'flypy_18)
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
  (custom "flypy_18.custom.yaml"
    (includes yuanshu_common_patch yuanshu_reverse_lookup_patch)
    (version "0.1")
    (description
     "朙月拼音＋小鶴雙拼 18 鍵方案。\n使用 rime-ice 詞庫，適合 Yuanshu iPhone 18 鍵圖示皮膚。")))
