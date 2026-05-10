#lang s-exp "lib/lang.rkt"

(rime-schema luna_pinyin
  (name "朙月拼音")
  (keyboard luna_pinyin
    (model standard-26)
    (meta
     (name "Luna Pinyin" "朙月拼音")
     (summary "A Yuanshu keyboard layout for standard full-pinyin typing.")
     (features
      "Standard QWERTY pinyin phone layout"
      "Standard iPad pinyin, numeric, and symbolic pages"))
    (print abc center #:font-size 25 #:role primary #:weight bold)
    (ipad standard-18))
  (static-files "luna_pinyin.dict.yaml" "zhuyin.yaml")
  (schema
   (version "0.1")
   (authors "Rime schema by 佛振 <chen.sst@gmail.com>")
   (description "朙月拼音全拼方案。")
   (switches
    (switch 'ascii_mode #:reset 0 #:states '("中" "A"))
    (switch 'simplification #:states '("漢字" "汉字"))
    (switch 'full_shape #:states '("半角" "全角"))
    (switch 'ascii_punct #:states '("。，" "．，")))
   (engine
    #:translators '(punct_translator reverse_lookup_translator script_translator))
   (speller
    #:alphabet "zyxwvutsrqponmlkjihgfedcba"
    #:delimiter " '"
    #:algebra
    '("erase/^xx$/"
      "derive/^([jqxy])u$/$1v/"
      "derive/^([aoe])([ioun])$/$1$1$2/"
      "xform/^([aoe])(ng)?$/$1$1$2/"))
   (translator #:dictionary 'luna_pinyin #:prism 'luna_pinyin)
   (preset-section 'punctuator)
   (preset-section 'key_binder)
   (recognizer
    #:patterns
    (list (pattern 'punct "^/([0-9]0?|[A-Za-z]+)$")))))
