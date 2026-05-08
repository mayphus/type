#lang racket/base

(require racket/list)

(provide generated-schema-ids
         generated-custom-ids
         generated-config-ids
         extra-schema-ids-with-mobile
         schema-source-id
         static-schema-deps
         static-schema-extra-files
         static-schema-extra-dirs
         static-schema-name
         static-schema-description
         static-schema-artifacts
         schema-display-names
         schema-display-descriptions
         schema-catalog-order
         schema-id->catalog-id
         schema-catalog-label
         schema-catalog-summary)

(define generated-schema-ids
  '("flypy"
    "flypy_14"
    "flypy_18"
    "flypy_ice"
    "luna_pinyin"
    "pinyin_14"
    "shuffle_17"
    "terra_pinyin"))

(define generated-custom-ids
  '("cangjie6"
    "flypy"
    "jyut6ping3"))

(define generated-config-ids
  (remove-duplicates (append generated-schema-ids generated-custom-ids)))

(define extra-schema-ids-with-mobile
  '("bopomofo"))

(define schema-source-ids
  (hash "flypy_ice" "flypy"))

(define (schema-source-id schema)
  (hash-ref schema-source-ids schema schema))

(define schema-display-metadata
  (hash
   "flypy"
   (hash 'names (hash 'en "Flypy" 'zh-Hant "小鶴")
         'descriptions
         (hash 'en "Flypy double pinyin with Rime config and Yuanshu keyboard layout previews."
               'zh-Hant "小鶴方案，提供 Rime 設定與元書鍵盤佈局預覽。"))
   "flypy_ice"
   (hash 'names (hash 'en "Flypy Ice" 'zh-Hant "小鶴-霧凇")
         'descriptions
         (hash 'en "Flypy double pinyin backed by rime-ice dictionaries, packaged for Yuanshu."
               'zh-Hant "使用 rime-ice 詞庫的小鶴方案，作為元書套件展品。"))
   "flypy_14"
   (hash 'names (hash 'en "Flypy 14-Key" 'zh-Hant "小鶴-14鍵")
         'descriptions
         (hash 'en "A 14-key Flypy double pinyin schema for Yuanshu, grouping adjacent QWERTY keys."
               'zh-Hant "14 鍵小鶴元書方案，按相鄰 QWERTY 鍵位分組。"))
   "flypy_18"
   (hash 'names (hash 'en "Flypy 18-Key" 'zh-Hant "小鶴-18鍵")
         'descriptions
         (hash 'en "An 18-key Flypy double pinyin schema for Yuanshu, adapted from a compact phone layout."
               'zh-Hant "18 鍵小鶴元書方案，改編自緊湊手機鍵盤佈局。"))
   "shuffle_17"
   (hash 'names (hash 'en "Flypy Shuffle 17-Key" 'zh-Hant "小鶴-亂序17鍵")
         'descriptions
         (hash 'en "An experimental 17-key shuffled Flypy schema for Yuanshu."
               'zh-Hant "實驗性的 17 鍵亂序小鶴元書方案。"))
   "luna_pinyin"
   (hash 'names (hash 'en "Luna Pinyin" 'zh-Hant "朙月拼音")
         'descriptions
         (hash 'en "Standard full-pinyin Mandarin input, available as both Rime config and Yuanshu package."
               'zh-Hant "標準全拼普通話輸入方案，可輸出 Rime 設定與元書套件。"))
   "terra_pinyin"
   (hash 'names (hash 'en "Terra Pinyin" 'zh-Hant "地球拼音")
         'descriptions
         (hash 'en "Full-pinyin Mandarin input with tone-number support and matching Yuanshu layout previews."
               'zh-Hant "支援聲調數字的全拼普通話輸入，並提供元書鍵盤佈局預覽。"))
   "pinyin_14"
   (hash 'names (hash 'en "Pinyin 14-Key" 'zh-Hant "朙月拼音-14鍵")
         'descriptions
         (hash 'en "A 14-key full-pinyin Yuanshu schema using adjacent QWERTY groups."
               'zh-Hant "14 鍵全拼元書方案，使用相鄰 QWERTY 分組。"))
   "double_pinyin"
   (hash 'names (hash 'en "Double Pinyin ZRM" 'zh-Hant "自然碼雙拼")
         'descriptions
         (hash 'en "Upstream Rime double-pinyin schema using the Ziranma layout."
               'zh-Hant "上游 Rime 自然碼雙拼方案。"))
   "double_pinyin_abc"
   (hash 'names (hash 'en "Double Pinyin ABC" 'zh-Hant "智能ABC雙拼")
         'descriptions
         (hash 'en "Upstream Rime double-pinyin schema using the Intelligent ABC layout."
               'zh-Hant "上游 Rime 智能 ABC 雙拼方案。"))
   "double_pinyin_flypy"
   (hash 'names (hash 'en "Double Pinyin Flypy" 'zh-Hant "小鶴雙拼")
         'descriptions
         (hash 'en "Upstream Rime double-pinyin schema using the Flypy layout."
               'zh-Hant "上游 Rime 小鶴雙拼方案。"))
   "double_pinyin_mspy"
   (hash 'names (hash 'en "Double Pinyin MSPY" 'zh-Hant "微軟雙拼")
         'descriptions
         (hash 'en "Upstream Rime double-pinyin schema using the Microsoft layout."
               'zh-Hant "上游 Rime 微軟雙拼方案。"))
   "double_pinyin_pyjj"
   (hash 'names (hash 'en "Double Pinyin PYJJ" 'zh-Hant "拼音加加雙拼")
         'descriptions
         (hash 'en "Upstream Rime double-pinyin schema using the Pinyin Jiajia layout."
               'zh-Hant "上游 Rime 拼音加加雙拼方案。"))
   "double_pinyin_st"
   (hash 'names (hash 'en "Double Pinyin ST" 'zh-Hant "四通雙拼")
         'descriptions
         (hash 'en "Upstream Rime double-pinyin schema using the Stone layout."
               'zh-Hant "上游 Rime 四通雙拼方案。"))
   "cangjie5"
   (hash 'names (hash 'en "Cangjie 5" 'zh-Hant "倉頡五代")
         'descriptions
         (hash 'en "Upstream Rime fifth-generation Cangjie shape input."
               'zh-Hant "上游 Rime 第五代倉頡字形輸入方案。"))
   "cangjie5_express"
   (hash 'names (hash 'en "Cangjie 5 Express" 'zh-Hant "倉頡五代·快打模式")
         'descriptions
         (hash 'en "Upstream Rime Cangjie 5 schema with express auto-selection behavior."
               'zh-Hant "上游 Rime 倉頡五代快打模式方案。"))
   "cangjie6"
   (hash 'names (hash 'en "Cangjie 6" 'zh-Hant "蒼頡六代")
         'descriptions
         (hash 'en "Sixth-generation Cangjie shape input with Rime config and Yuanshu keyboard layout support."
               'zh-Hant "第六代蒼頡字形輸入，提供 Rime 設定與元書鍵盤佈局。"))
   "wubi86"
   (hash 'names (hash 'en "Wubi 86" 'zh-Hant "五筆86")
         'descriptions
         (hash 'en "Upstream Rime Wubi 86 shape input."
               'zh-Hant "上游 Rime 五筆 86 字形輸入方案。"))
   "wubi_pinyin"
   (hash 'names (hash 'en "Wubi Pinyin" 'zh-Hant "五筆·拼音")
         'descriptions
         (hash 'en "Upstream Rime Wubi schema with pinyin mixed input."
               'zh-Hant "上游 Rime 五筆拼音混輸方案。"))
   "wubi_trad"
   (hash 'names (hash 'en "Wubi Traditional" 'zh-Hant "五筆·簡入繁出")
         'descriptions
         (hash 'en "Upstream Rime Wubi schema for simplified input with traditional output."
               'zh-Hant "上游 Rime 五筆簡入繁出方案。"))
   "quick5"
   (hash 'names (hash 'en "Quick 5" 'zh-Hant "速成")
         'descriptions
         (hash 'en "Upstream Rime Quick 5 shape input derived from Cangjie."
               'zh-Hant "上游 Rime 速成五代字形輸入方案。"))
   "stroke"
   (hash 'names (hash 'en "Stroke" 'zh-Hant "五筆畫")
         'descriptions
         (hash 'en "Supporting five-stroke lookup schema used by upstream double-pinyin and Wubi packages."
               'zh-Hant "上游雙拼與五筆方案使用的五筆畫反查支援方案。"))
   "pinyin_simp"
   (hash 'names (hash 'en "Pinyin Simplified" 'zh-Hant "袖珍簡化字拼音")
         'descriptions
         (hash 'en "Supporting simplified pinyin schema used by upstream Wubi packages."
               'zh-Hant "上游五筆方案使用的簡化字拼音反查支援方案。"))
   "luna_quanpin"
   (hash 'names (hash 'en "Luna Quanpin" 'zh-Hant "全拼")
         'descriptions
         (hash 'en "Supporting full-pinyin reverse-lookup schema used by upstream Cangjie and Quick packages."
               'zh-Hant "上游倉頡與速成方案使用的全拼反查支援方案。"))
   "jyut6ping3"
   (hash 'names (hash 'en "Jyutping" 'zh-Hant "粵拼")
         'descriptions
         (hash 'en "Jyutping Cantonese input with Cantonese dictionaries and Yuanshu keyboard layout support."
               'zh-Hant "香港語言學會粵拼輸入，包含粵語詞庫與元書鍵盤佈局。"))
   "bopomofo"
   (hash 'names (hash 'en "Bopomofo" 'zh-Hant "注音")
         'descriptions
         (hash 'en "Bopomofo phonetic input for Mandarin, arranged for Yuanshu keyboard layouts."
               'zh-Hant "注音符號普通話輸入，配置為元書鍵盤佈局。"))))

(define static-schema-metadata
  (hash "bopomofo" (hash 'deps '()
                         'artifacts '("yuanshu"))
        "double_pinyin" (hash 'deps '("stroke")
                              'artifacts '("rime"))
        "double_pinyin_abc" (hash 'deps '("stroke")
                                  'artifacts '("rime"))
        "double_pinyin_flypy" (hash 'deps '("stroke")
                                    'artifacts '("rime"))
        "double_pinyin_mspy" (hash 'deps '("stroke")
                                   'artifacts '("rime"))
        "double_pinyin_pyjj" (hash 'deps '("stroke")
                                   'artifacts '("rime"))
        "double_pinyin_st" (hash 'deps '("stroke")
                                 'artifacts '("rime"))
        "cangjie5" (hash 'deps '("luna_quanpin")
                         'artifacts '("rime")
                         'files '("cangjie5.dict.yaml"))
        "cangjie5_express" (hash 'deps '("luna_quanpin")
                                 'artifacts '("rime")
                                 'files '("cangjie5.dict.yaml"))
        "cangjie6" (hash 'deps '("flypy")
                         'artifacts '("rime" "yuanshu"))
        "wubi86" (hash 'deps '("pinyin_simp")
                       'artifacts '("rime")
                       'files '("wubi86.dict.yaml"))
        "wubi_pinyin" (hash 'deps '("pinyin_simp")
                            'artifacts '("rime")
                            'files '("wubi86.dict.yaml"))
        "wubi_trad" (hash 'deps '("pinyin_simp")
                          'artifacts '("rime")
                          'files '("wubi86.dict.yaml"))
        "quick5" (hash 'deps '("luna_quanpin")
                       'artifacts '("rime")
                       'files '("quick5.dict.yaml"))
        "stroke" (hash 'deps '("luna_pinyin")
                       'artifacts '("rime")
                       'files '("stroke.dict.yaml"))
        "pinyin_simp" (hash 'deps '("stroke")
                            'artifacts '("rime")
                            'files '("pinyin_simp.dict.yaml"))
        "luna_quanpin" (hash 'deps '("luna_pinyin")
                             'artifacts '("rime")
                             'files '("pinyin.yaml"))
        "jyut6ping3" (hash 'deps '("flypy" "cangjie6")
                           'artifacts '("rime" "yuanshu"))))

(define (localized-value values locale [default #f])
  (cond
    [(hash? values)
     (hash-ref values locale
               (lambda ()
                 (hash-ref values 'en
                           (lambda ()
                             (hash-ref values 'zh-Hant default)))))]
    [else values]))

(define (schema-display-ref schema key)
  (hash-ref (hash-ref schema-display-metadata schema (hash)) key #f))

(define (schema-display-names schema)
  (schema-display-ref schema 'names))

(define (schema-display-descriptions schema)
  (schema-display-ref schema 'descriptions))

(define (static-schema-deps schema)
  (hash-ref (hash-ref static-schema-metadata schema (hash)) 'deps '()))

(define (static-schema-extra-files schema)
  (hash-ref (hash-ref static-schema-metadata schema (hash)) 'files '()))

(define (static-schema-extra-dirs schema)
  (hash-ref (hash-ref static-schema-metadata schema (hash)) 'dirs '()))

(define (static-schema-name schema)
  (localized-value (schema-display-names schema) 'zh-Hant))

(define (static-schema-description schema)
  (localized-value (schema-display-descriptions schema) 'en))

(define (static-schema-artifacts schema)
  (hash-ref (hash-ref static-schema-metadata schema (hash)) 'artifacts '("rime" "yuanshu")))

(define schema-catalog-order
  '("double-pinyin" "full-pinyin" "shape" "phonetic" "other"))

(define (schema-id->catalog-id id)
  (cond
    [(member id '("flypy" "flypy_ice" "flypy_14" "flypy_18" "shuffle_17"
                  "double_pinyin" "double_pinyin_abc" "double_pinyin_flypy"
                  "double_pinyin_mspy" "double_pinyin_pyjj" "double_pinyin_st"))
     "double-pinyin"]
    [(member id '("luna_pinyin" "terra_pinyin" "pinyin_14" "jyut6ping3"
                  "luna_quanpin" "pinyin_simp"))
     "full-pinyin"]
    [(member id '("cangjie5" "cangjie5_express" "cangjie6" "wubi86"
                  "wubi_pinyin" "wubi_trad" "quick5" "stroke"))
     "shape"]
    [(equal? id "bopomofo") "phonetic"]
    [else "other"]))

(define catalog-labels
  (hash "double-pinyin" (hash 'en "Double Pinyin" 'zh-Hant "雙拼")
        "full-pinyin" (hash 'en "Full Spelling" 'zh-Hant "全拼")
        "shape" (hash 'en "Shape" 'zh-Hant "字形")
        "phonetic" (hash 'en "Phonetic" 'zh-Hant "注音")
        "other" (hash 'en "Other" 'zh-Hant "其他")))

(define catalog-summaries
  (hash "double-pinyin"
        (hash 'en "Compact phonetic systems that trade full syllable spelling for paired initials and finals."
              'zh-Hant "以聲母和韻母配對取代完整拼音的緊湊音碼方案。")
        "full-pinyin"
        (hash 'en "Full syllable-spelling systems, including Mandarin pinyin and Cantonese Jyutping."
              'zh-Hant "完整拼音式音節輸入，包含普通話拼音與粵拼。")
        "shape"
        (hash 'en "Shape-based methods that encode character structure rather than pronunciation."
              'zh-Hant "依字形結構取碼，而不是依照讀音輸入。")
        "phonetic"
        (hash 'en "Keyboard layouts based on phonetic symbols rather than Latin pinyin letters."
              'zh-Hant "以注音符號而非拉丁拼音字母為核心的鍵盤佈局。")
        "other"
        (hash 'en "Additional input experiments and supporting schemas."
              'zh-Hant "其他輸入實驗與支援方案。")))

(define (schema-catalog-label catalog-id [locale 'en])
  (localized-value (hash-ref catalog-labels catalog-id #f) locale catalog-id))

(define (schema-catalog-summary catalog-id [locale 'en])
  (localized-value (hash-ref catalog-summaries catalog-id #f)
                   locale
                   (localized-value (hash-ref catalog-summaries "other") locale)))
