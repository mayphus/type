#lang s-exp "lib/lang.rkt"

(rime-schema jyut6ping3
  (name "粵拼")
  (keyboard jyut6ping3
    (model standard-26)
    (meta
     (name "Jyutping" "粵拼")
     (summary "A Yuanshu keyboard layout for Jyutping Cantonese input.")
     (features
      "Jyutping vowel clusters and Cantonese digraph initials"
      "Q/R/V/X marked as unused in Jyutping spelling"))
    (print abc top #:font-size 10 #:role secondary)
    (print jyutping center #:font-size 12 #:role primary)
    (ipad
     (raw
      (ipad-layout
       (layers abc jyutping)
       (size "1.1/16")
       (positions
        (abc      top)
        (jyutping center))
       (fonts
        (abc      11 #:secondary)
        (jyutping 14 #:primary))))))
  (static-files "jyut6ping3.dict.yaml" "symbols_cantonese.yaml")
  (static-dirs "jyut6ping3_dicts")
  (custom "jyut6ping3.custom.yaml"
    (includes yuanshu_common_patch)
    (version "0.1")
    (description "香港語言學學會粵拼方案。\n精簡版，適合移動端匯入")
    (patch "recognizer/patterns/punct" "^/([0-9]0?|[a-z]+)$")
    (patch "recognizer/patterns/flypy" "^`[a-z']*;?$")
    (patch "recognizer/patterns/cangjie6" "^v[a-z]*;?$")))
