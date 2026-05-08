#lang racket/base

(require racket/list
         "model.rkt")

(provide schema-definitions
         schema-definition-ref
         schema-definition-ids
         generated-schema-ids
         generated-custom-ids
         generated-config-ids
         extra-schema-ids-with-mobile
         schema-catalog-order
         schema-catalog-label
         schema-catalog-summary)

(define (schema id
                #:source-id [source-id id]
                #:kind [kind 'static]
                #:catalog [catalog "other"]
                #:artifacts [artifacts '("rime" "yuanshu")]
                #:deps [deps '()]
                #:static-files [static-files '()]
                #:static-dirs [static-dirs '()]
                #:keyboard-layouts [keyboard-layouts '()]
                #:en-name en-name
                #:zh-name zh-name
                #:en-description en-description
                #:zh-description zh-description)
  (make-schema-definition
   #:id id
   #:source-id source-id
   #:kind kind
   #:catalog catalog
   #:artifacts artifacts
   #:deps deps
   #:static-files static-files
   #:static-dirs static-dirs
   #:keyboard-layouts keyboard-layouts
   #:names (hash 'en en-name 'zh-Hant zh-name)
   #:descriptions (hash 'en en-description 'zh-Hant zh-description)))

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

(define schema-definitions
  (list
   (schema "flypy"
           #:kind 'generated
           #:catalog "double-pinyin"
           #:en-name "Flypy"
           #:zh-name "小鶴"
           #:en-description "Flypy double pinyin with Rime config and Yuanshu keyboard layout previews."
           #:zh-description "小鶴方案，提供 Rime 設定與元書鍵盤佈局預覽。")
   (schema "flypy_ice"
           #:source-id "flypy"
           #:kind 'variant
           #:catalog "double-pinyin"
           #:en-name "Flypy Ice"
           #:zh-name "小鶴-霧凇"
           #:en-description "Flypy double pinyin backed by rime-ice dictionaries, packaged for Yuanshu."
           #:zh-description "使用 rime-ice 詞庫的小鶴方案，作為元書套件展品。")
   (schema "flypy_14"
           #:kind 'generated
           #:catalog "double-pinyin"
           #:en-name "Flypy 14-Key"
           #:zh-name "小鶴-14鍵"
           #:en-description "A 14-key Flypy double pinyin schema for Yuanshu, grouping adjacent QWERTY keys."
           #:zh-description "14 鍵小鶴元書方案，按相鄰 QWERTY 鍵位分組。")
   (schema "flypy_18"
           #:kind 'generated
           #:catalog "double-pinyin"
           #:en-name "Flypy 18-Key"
           #:zh-name "小鶴-18鍵"
           #:en-description "An 18-key Flypy double pinyin schema for Yuanshu, adapted from a compact phone layout."
           #:zh-description "18 鍵小鶴元書方案，改編自緊湊手機鍵盤佈局。")
   (schema "shuffle_17"
           #:kind 'generated
           #:catalog "double-pinyin"
           #:en-name "Flypy Shuffle 17-Key"
           #:zh-name "小鶴-亂序17鍵"
           #:en-description "An experimental 17-key shuffled Flypy schema for Yuanshu."
           #:zh-description "實驗性的 17 鍵亂序小鶴元書方案。")
   (schema "luna_pinyin"
           #:kind 'generated
           #:catalog "full-pinyin"
           #:en-name "Luna Pinyin"
           #:zh-name "朙月拼音"
           #:en-description "Standard full-pinyin Mandarin input, available as both Rime config and Yuanshu package."
           #:zh-description "標準全拼普通話輸入方案，可輸出 Rime 設定與元書套件。")
   (schema "terra_pinyin"
           #:kind 'generated
           #:catalog "full-pinyin"
           #:en-name "Terra Pinyin"
           #:zh-name "地球拼音"
           #:en-description "Full-pinyin Mandarin input with tone-number support and matching Yuanshu layout previews."
           #:zh-description "支援聲調數字的全拼普通話輸入，並提供元書鍵盤佈局預覽。")
   (schema "pinyin_14"
           #:kind 'generated
           #:catalog "full-pinyin"
           #:en-name "Pinyin 14-Key"
           #:zh-name "朙月拼音-14鍵"
           #:en-description "A 14-key full-pinyin Yuanshu schema using adjacent QWERTY groups."
           #:zh-description "14 鍵全拼元書方案，使用相鄰 QWERTY 分組。")
   (schema "double_pinyin"
           #:catalog "double-pinyin"
           #:artifacts '("rime")
           #:deps '("stroke")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Double Pinyin ZRM"
           #:zh-name "自然碼雙拼"
           #:en-description "Upstream Rime double-pinyin schema using the Ziranma layout."
           #:zh-description "上游 Rime 自然碼雙拼方案。")
   (schema "double_pinyin_abc"
           #:catalog "double-pinyin"
           #:artifacts '("rime")
           #:deps '("stroke")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Double Pinyin ABC"
           #:zh-name "智能ABC雙拼"
           #:en-description "Upstream Rime double-pinyin schema using the Intelligent ABC layout."
           #:zh-description "上游 Rime 智能 ABC 雙拼方案。")
   (schema "double_pinyin_flypy"
           #:catalog "double-pinyin"
           #:artifacts '("rime")
           #:deps '("stroke")
           #:keyboard-layouts '("flypy")
           #:en-name "Double Pinyin Flypy"
           #:zh-name "小鶴雙拼"
           #:en-description "Upstream Rime double-pinyin schema using the Flypy layout."
           #:zh-description "上游 Rime 小鶴雙拼方案。")
   (schema "double_pinyin_mspy"
           #:catalog "double-pinyin"
           #:artifacts '("rime")
           #:deps '("stroke")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Double Pinyin MSPY"
           #:zh-name "微軟雙拼"
           #:en-description "Upstream Rime double-pinyin schema using the Microsoft layout."
           #:zh-description "上游 Rime 微軟雙拼方案。")
   (schema "double_pinyin_pyjj"
           #:catalog "double-pinyin"
           #:artifacts '("rime")
           #:deps '("stroke")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Double Pinyin PYJJ"
           #:zh-name "拼音加加雙拼"
           #:en-description "Upstream Rime double-pinyin schema using the Pinyin Jiajia layout."
           #:zh-description "上游 Rime 拼音加加雙拼方案。")
   (schema "double_pinyin_st"
           #:catalog "double-pinyin"
           #:artifacts '("rime")
           #:deps '("stroke")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Double Pinyin ST"
           #:zh-name "四通雙拼"
           #:en-description "Upstream Rime double-pinyin schema using the Stone layout."
           #:zh-description "上游 Rime 四通雙拼方案。")
   (schema "cangjie5"
           #:catalog "shape"
           #:artifacts '("rime")
           #:deps '("luna_quanpin")
           #:static-files '("cangjie5.dict.yaml")
           #:keyboard-layouts '("cangjie6")
           #:en-name "Cangjie 5"
           #:zh-name "倉頡五代"
           #:en-description "Upstream Rime fifth-generation Cangjie shape input."
           #:zh-description "上游 Rime 第五代倉頡字形輸入方案。")
   (schema "cangjie5_express"
           #:catalog "shape"
           #:artifacts '("rime")
           #:deps '("luna_quanpin")
           #:static-files '("cangjie5.dict.yaml")
           #:keyboard-layouts '("cangjie6")
           #:en-name "Cangjie 5 Express"
           #:zh-name "倉頡五代·快打模式"
           #:en-description "Upstream Rime Cangjie 5 schema with express auto-selection behavior."
           #:zh-description "上游 Rime 倉頡五代快打模式方案。")
   (schema "cangjie6"
           #:kind 'generated
           #:catalog "shape"
           #:artifacts '("rime" "yuanshu")
           #:deps '("flypy")
           #:en-name "Cangjie 6"
           #:zh-name "蒼頡六代"
           #:en-description "Sixth-generation Cangjie shape input with Rime config and Yuanshu keyboard layout support."
           #:zh-description "第六代蒼頡字形輸入，提供 Rime 設定與元書鍵盤佈局。")
   (schema "wubi86"
           #:catalog "shape"
           #:artifacts '("rime")
           #:deps '("pinyin_simp")
           #:static-files '("wubi86.dict.yaml")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Wubi 86"
           #:zh-name "五筆86"
           #:en-description "Upstream Rime Wubi 86 shape input."
           #:zh-description "上游 Rime 五筆 86 字形輸入方案。")
   (schema "wubi_pinyin"
           #:catalog "shape"
           #:artifacts '("rime")
           #:deps '("pinyin_simp")
           #:static-files '("wubi86.dict.yaml")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Wubi Pinyin"
           #:zh-name "五筆·拼音"
           #:en-description "Upstream Rime Wubi schema with pinyin mixed input."
           #:zh-description "上游 Rime 五筆拼音混輸方案。")
   (schema "wubi_trad"
           #:catalog "shape"
           #:artifacts '("rime")
           #:deps '("pinyin_simp")
           #:static-files '("wubi86.dict.yaml")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Wubi Traditional"
           #:zh-name "五筆·簡入繁出"
           #:en-description "Upstream Rime Wubi schema for simplified input with traditional output."
           #:zh-description "上游 Rime 五筆簡入繁出方案。")
   (schema "quick5"
           #:catalog "shape"
           #:artifacts '("rime")
           #:deps '("luna_quanpin")
           #:static-files '("quick5.dict.yaml")
           #:keyboard-layouts '("cangjie6")
           #:en-name "Quick 5"
           #:zh-name "速成"
           #:en-description "Upstream Rime Quick 5 shape input derived from Cangjie."
           #:zh-description "上游 Rime 速成五代字形輸入方案。")
   (schema "stroke"
           #:catalog "shape"
           #:artifacts '("rime")
           #:deps '("luna_pinyin")
           #:static-files '("stroke.dict.yaml")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Stroke"
           #:zh-name "五筆畫"
           #:en-description "Supporting five-stroke lookup schema used by upstream double-pinyin and Wubi packages."
           #:zh-description "上游雙拼與五筆方案使用的五筆畫反查支援方案。")
   (schema "pinyin_simp"
           #:catalog "full-pinyin"
           #:artifacts '("rime")
           #:deps '("stroke")
           #:static-files '("pinyin_simp.dict.yaml")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Pinyin Simplified"
           #:zh-name "袖珍簡化字拼音"
           #:en-description "Supporting simplified pinyin schema used by upstream Wubi packages."
           #:zh-description "上游五筆方案使用的簡化字拼音反查支援方案。")
   (schema "luna_quanpin"
           #:catalog "full-pinyin"
           #:artifacts '("rime")
           #:deps '("luna_pinyin")
           #:static-files '("pinyin.yaml")
           #:keyboard-layouts '("luna_pinyin")
           #:en-name "Luna Quanpin"
           #:zh-name "全拼"
           #:en-description "Supporting full-pinyin reverse-lookup schema used by upstream Cangjie and Quick packages."
           #:zh-description "上游倉頡與速成方案使用的全拼反查支援方案。")
   (schema "jyut6ping3"
           #:kind 'generated
           #:catalog "full-pinyin"
           #:artifacts '("rime" "yuanshu")
           #:deps '("flypy" "cangjie6")
           #:en-name "Jyutping"
           #:zh-name "粵拼"
           #:en-description "Jyutping Cantonese input with Cantonese dictionaries and Yuanshu keyboard layout support."
           #:zh-description "香港語言學會粵拼輸入，包含粵語詞庫與元書鍵盤佈局。")
   (schema "bopomofo"
           #:catalog "phonetic"
           #:artifacts '("yuanshu")
           #:en-name "Bopomofo"
           #:zh-name "注音"
           #:en-description "Bopomofo phonetic input for Mandarin, arranged for Yuanshu keyboard layouts."
           #:zh-description "注音符號普通話輸入，配置為元書鍵盤佈局。")))

(define (schema-definition-ids)
  (map schema-definition-id schema-definitions))

(define schema-definition-by-id
  (for/hash ([definition (in-list schema-definitions)])
    (values (schema-definition-id definition) definition)))

(define (schema-definition-ref id [default #f])
  (hash-ref schema-definition-by-id id default))

(define schema-catalog-order
  '("double-pinyin" "full-pinyin" "shape" "phonetic" "other"))

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
  (localized-schema-value (hash-ref catalog-labels catalog-id #f) locale catalog-id))

(define (schema-catalog-summary catalog-id [locale 'en])
  (localized-schema-value (hash-ref catalog-summaries catalog-id #f)
                          locale
                          (localized-schema-value (hash-ref catalog-summaries "other")
                                                  locale)))
