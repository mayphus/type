#lang s-exp "lib/lang.rkt"

(rime-schema pinyin_14
  (name "朙月拼音-14鍵")
  (artifacts yuanshu)
  (keyboard pinyin_14
    (model compact-14)
    (meta
     (name "Pinyin-14 Key" "朙月拼音-14鍵")
     (summary "A compact Yuanshu keyboard layout for the full-pinyin 14-key layout.")
     (features
      "14-key full-pinyin phone layout"
      "Standard iPad pinyin page and secondary pages"))
    (variant pinyin-14)
    (print abc center)
    (ipad standard-18))
  (deps cangjie6)
  (static-files "rime_ice.dict.yaml")
  (static-dirs "rime_ice_dicts")
  (schema
   (version "0.1")
   (authors
    "14-key adjacent QWERTY merge layout adapted in this workspace"
    "dictionary import from iDvel/rime-ice")
   (description
    "朙月拼音全拼 14 鍵方案，使用 rime-ice 詞庫。\niPhone 佈局按相鄰 QWERTY 分組：\nQW / ER / TY / UI / OP\nAS / DF / GH / JK / L\nZX / CV / BN / M")
   (switches
    (switch 'ascii_mode #:reset 0 #:states '("全拼14" "A"))
    (switch 'simplification #:states '("漢字" "汉字"))
    (switch 'full_shape #:states '("半角" "全角"))
    (switch 'ascii_punct #:states '("。，" "．，")))
   (engine
    #:translators '(punct_translator reverse_lookup_translator script_translator))
   (speller
    #:alphabet "qetuoadgjlzcbm"
    #:delimiter " '"
    #:algebra
    '("erase/^xx$/"
      "derive/^([jqxy])u/$1v/"
      "derive/^([nl])v/$1u/"
      "xlit/qwertyuiopasdfghjklzxcvbnm/qqeettuuooaaddggjjlzzccbbm/"))
   (translator #:dictionary 'rime_ice #:prism 'pinyin_14)
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
  (custom "pinyin_14.custom.yaml"
    (includes yuanshu_common_patch yuanshu_reverse_lookup_patch)
    (version "0.1")
    (description
     "朙月拼音全拼 14 鍵方案。\n使用 rime-ice 詞庫，適合 Yuanshu iPhone 14 鍵圖示皮膚。")))
