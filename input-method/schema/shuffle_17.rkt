#lang s-exp "lib/lang.rkt"

(rime-schema shuffle_17
  (name "小鶴雙拼-亂序17鍵")
  (artifacts yuanshu)
  (keyboard shuffle_17
    (model compact-17)
    (meta
     (name "Flypy-Shuffle 17 Key" "小鶴-亂序17鍵")
     (summary "An experimental 17-key Yuanshu keyboard layout for the shuffle_17 schema family.")
     (features
      "17-key shuffled phone layout"
      "Custom iPad pages"))
    (variant shuffle-17)
    (print flypy center))
  (static-files "rime_ice.dict.yaml")
  (static-dirs "rime_ice_dicts")
  (schema
   (version "0.1")
   (authors
    "layout reference from Log Input docs"
    "dictionary import from iDvel/rime-ice"
    "Rime schema adapted in this workspace")
   (description
    "朙月拼音＋亂序17方案，使用 rime-ice 詞庫。\n移動端優先，17 鍵內碼採用 a-q。")
   (switches
    (switch 'ascii_mode #:reset 0 #:states '("17" "A"))
    (switch 'simplification #:states '("漢字" "汉字"))
    (switch 'full_shape #:states '("半角" "全角"))
    (switch 'ascii_punct #:states '("。，" "．，")))
   (engine #:translators '(punct_translator script_translator))
   (speller
    #:alphabet "abcdefghijklmnopq"
    #:delimiter " '"
    #:algebra
    '("xform/^(a|ai|an|ang|ao|e|ei|en|eng|er|o|ou)$/N$1/"
      "xform/^([jqxy])u$/$1v/"
      "xform/^sh/B/"
      "xform/^zh/C/"
      "xform/^ch/M/"
      "xform/^(h|p)/A/"
      "xform/^b/D/"
      "xform/^x/E/"
      "xform/^(s|m)/F/"
      "xform/^l/G/"
      "xform/^d/H/"
      "xform/^y/I/"
      "xform/^(w|z)/J/"
      "xform/^(j|k)/K/"
      "xform/^(r|n)/L/"
      "xform/^q/N/"
      "xform/^g/O/"
      "xform/^(c|f)/P/"
      "xform/^t/Q/"
      "xform/(iang|ui)$/M/"
      "xform/(uang|ian)$/N/"
      "xform/iong$/D/"
      "xform/iao$/C/"
      "xform/(uai|uan)$/E/"
      "xform/(ie|uo)$/F/"
      "xform/(ue|ve|ai)$/G/"
      "xform/(eng|ing)$/I/"
      "xform/(iu|ou)$/P/"
      "xform/(er|ong)$/Q/"
      "xform/(ia|ua)$/A/"
      "xform/(en|in)$/B/"
      "xform/ao$/D/"
      "xform/ang$/C/"
      "xform/(ei|un)$/O/"
      "xform/(o|v)$/E/"
      "xform/a$/A/"
      "xform/u$/H/"
      "xform/e$/J/"
      "xform/i$/K/"
      "xform/an$/L/"
      "xlit/ABCDEFGHIJKLMNOPQ/abcdefghijklmnopq/"))
   (translator #:dictionary 'rime_ice #:prism 'shuffle_17)
   (preset-section 'punctuator)
   (preset-section 'key_binder)
   (recognizer))
  (custom "shuffle_17.custom.yaml"
    (includes yuanshu_common_patch yuanshu_script_patch)
    (version "0.1")
    (description
     "朙月拼音＋亂序17方案。\n使用 rime-ice 詞庫，精簡版，適合移動端匯入")))
