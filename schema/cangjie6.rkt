#lang s-exp "lib/lang.rkt"

(rime-schema cangjie6
  (name "蒼頡六代")
  (mobile-skins cangjie6)
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
    (patch "recognizer/patterns/reverse_lookup" "`[a-z]*;?$"))
  (mobile-skin cangjie6
    (meta
      (name "Cangjie 6" "倉頡六代")
      (summary "A Yuanshu skin focused on Cangjie 6 labels across phone and iPad layouts.")
      (features
        "Cangjie-centered legends"
        "Standard numeric and symbolic secondary pages"))
    (phone-layout
      (layers cangjie)
      (fonts [cangjie 14 #:weight bold]))
    (ipad-layout
      (layers cangjie)
      (size "1.1/16")
      (fonts
        [cangjie 17.5 #:weight bold]))))
