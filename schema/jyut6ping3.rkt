#lang s-exp "lib/lang.rkt"

(rime-schema jyut6ping3
  (name "粵拼")
  (keyboard-layout jyut6ping3
    (meta
     (name "Jyutping" "粵拼")
     (summary "A Yuanshu keyboard layout for Jyutping Cantonese input.")
     (features
      "Standard QWERTY Jyutping phone layout"
      "Standard iPad pinyin, numeric, and symbolic pages"))
    (phone-layout
     (layers abc)
     (positions (abc center))
     (fonts (abc 25 #:primary #:weight bold)))
    (ipad-layout standard-18))
  (static-files "jyut6ping3.dict.yaml" "symbols_cantonese.yaml")
  (static-dirs "jyut6ping3_dicts")
  (custom "jyut6ping3.custom.yaml"
    (includes yuanshu_common_patch)
    (version "0.1")
    (description "香港語言學學會粵拼方案。\n精簡版，適合移動端匯入")
    (patch "recognizer/patterns/punct" "^/([0-9]0?|[a-z]+)$")
    (patch "recognizer/patterns/flypy" "^`[a-z']*;?$")
    (patch "recognizer/patterns/cangjie6" "^v[a-z]*;?$")))
