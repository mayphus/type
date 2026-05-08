#lang s-exp "lib/lang.rkt"

(rime-schema cangjie6
  (name "蒼頡六代")
  (keyboard cangjie6
    (model standard-26)
    (meta
     (name "Cangjie 6" "倉頡六代")
     (summary "A Yuanshu keyboard layout focused on Cangjie 6 labels across phone and iPad layouts.")
     (features
      "Cangjie-centered legends"
      "Standard numeric and symbolic secondary pages"))
    (print cangjie center #:font-size 25 #:role primary)
    (ipad
     (raw
      (ipad-layout
       (layers cangjie)
       (size "1.1/16")
       (fonts
        (cangjie 22.5 #:primary))))))
  (deps flypy)
  (static-files "cangjie6.dict.yaml")
  (custom "cangjie6.custom.yaml"
    (includes yuanshu_common_patch)
    (description "第六代蒼頡檢字法\n精簡版，適合移動端匯入")
    (patch "translator/dictionary" 'cangjie6)
    (patch "flypy_reverse_lookup/dictionary" 'cangjie6)
    (patch "engine/filters" '("simplifier@simplify"
                              "reverse_lookup_filter@flypy_reverse_lookup"
                              "uniquifier"))
    (patch "recognizer/patterns/reverse_lookup" "`[a-z]*;?$")))
