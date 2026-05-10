#lang s-exp "lib/lang.rkt"

(rime-schema terra_pinyin
  (name "地球拼音")
  (keyboard terra_pinyin
    (model standard-26)
    (meta
     (name "Terra Pinyin" "地球拼音")
     (summary "A Yuanshu keyboard layout for Terra Pinyin with tone-number input.")
     (features
      "Standard QWERTY pinyin phone layout"
      "Standard iPad pinyin, numeric, and symbolic pages"))
    (print abc center #:font-size 25 #:role primary #:weight bold)
    (ipad standard-18))
  (static-files "terra_pinyin.dict.yaml")
  (schema
   (version "0.1")
   (authors "Rime schema by 佛振 <chen.sst@gmail.com>")
   (description "地球拼音全拼方案，使用帶聲調拼音詞庫。")
   (switches
    (switch 'ascii_mode #:reset 0 #:states '("地" "A"))
    (switch 'simplification #:states '("漢字" "汉字"))
    (switch 'full_shape #:states '("半角" "全角"))
    (switch 'ascii_punct #:states '("。，" "．，")))
   (engine
    #:translators '(punct_translator script_translator))
   (speller
    #:alphabet "zyxwvutsrqponmlkjihgfedcba12345"
    #:delimiter " '"
    #:algebra
    '("erase/^xx$/"
      "derive/^([jqxy])u/$1v/"
      "derive/^([nl])v/$1u/"
      "derive/([aeiou])ng([1-5])$/$1gn$2/"
      "derive/([aeiou])n([1-5])$/$1ng$2/"
      "derive/([aeiou])([1-5])$/$1/"))
   (translator #:dictionary 'terra_pinyin #:prism 'terra_pinyin)
   (preset-section 'punctuator)
   (preset-section 'key_binder)
   (recognizer
    #:patterns
    (list (pattern 'punct "^/([0-9]0?|[A-Za-z]+)$")))))
