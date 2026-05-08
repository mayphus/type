#lang racket/base

(require racket/list)

(provide generated-schema-ids
         generated-custom-ids
         generated-config-ids
         extra-schema-ids-with-mobile
         schema-source-id
         static-schema-deps
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
   (hash 'names (hash 'en "Flypy" 'zh-Hant "小鶴雙拼")
         'descriptions
         (hash 'en "Flypy double pinyin with Rime config and Yuanshu keyboard layout previews."
               'zh-Hant "小鶴雙拼方案，提供 Rime 設定與元書鍵盤佈局預覽。"))
   "flypy_ice"
   (hash 'names (hash 'en "Flypy Ice" 'zh-Hant "小鶴雙拼-霧凇")
         'descriptions
         (hash 'en "Flypy double pinyin backed by rime-ice dictionaries, packaged for Yuanshu."
               'zh-Hant "使用 rime-ice 詞庫的小鶴雙拼，作為元書套件展品。"))
   "flypy_14"
   (hash 'names (hash 'en "Flypy 14-Key" 'zh-Hant "小鶴雙拼-14鍵")
         'descriptions
         (hash 'en "A 14-key Flypy double pinyin schema for Yuanshu, grouping adjacent QWERTY keys."
               'zh-Hant "14 鍵小鶴雙拼元書方案，按相鄰 QWERTY 鍵位分組。"))
   "flypy_18"
   (hash 'names (hash 'en "Flypy 18-Key" 'zh-Hant "小鶴雙拼-18鍵")
         'descriptions
         (hash 'en "An 18-key Flypy double pinyin schema for Yuanshu, adapted from a compact phone layout."
               'zh-Hant "18 鍵小鶴雙拼元書方案，改編自緊湊手機鍵盤佈局。"))
   "shuffle_17"
   (hash 'names (hash 'en "Flypy Shuffle 17-Key" 'zh-Hant "小鶴雙拼-亂序17鍵")
         'descriptions
         (hash 'en "An experimental 17-key shuffled Flypy schema for Yuanshu."
               'zh-Hant "實驗性的 17 鍵亂序小鶴雙拼元書方案。"))
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
   "cangjie6"
   (hash 'names (hash 'en "Cangjie 6" 'zh-Hant "蒼頡六代")
         'descriptions
         (hash 'en "Sixth-generation Cangjie shape input with Rime config and Yuanshu keyboard layout support."
               'zh-Hant "第六代蒼頡字形輸入，提供 Rime 設定與元書鍵盤佈局。"))
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
        "cangjie6" (hash 'deps '("flypy")
                         'artifacts '("rime" "yuanshu"))
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

(define (static-schema-name schema)
  (localized-value (schema-display-names schema) 'zh-Hant))

(define (static-schema-description schema)
  (localized-value (schema-display-descriptions schema) 'en))

(define (static-schema-artifacts schema)
  (hash-ref (hash-ref static-schema-metadata schema (hash)) 'artifacts '("rime" "yuanshu")))

(define schema-catalog-order
  '("double-pinyin" "full-pinyin" "shape" "cantonese" "phonetic" "other"))

(define (schema-id->catalog-id id)
  (cond
    [(member id '("flypy" "flypy_ice" "flypy_14" "flypy_18" "shuffle_17")) "double-pinyin"]
    [(member id '("luna_pinyin" "terra_pinyin" "pinyin_14")) "full-pinyin"]
    [(equal? id "cangjie6") "shape"]
    [(equal? id "jyut6ping3") "cantonese"]
    [(equal? id "bopomofo") "phonetic"]
    [else "other"]))

(define catalog-labels
  (hash "double-pinyin" (hash 'en "Double Pinyin" 'zh-Hant "雙拼")
        "full-pinyin" (hash 'en "Full Pinyin" 'zh-Hant "全拼")
        "shape" (hash 'en "Shape" 'zh-Hant "字形")
        "cantonese" (hash 'en "Cantonese" 'zh-Hant "粵語")
        "phonetic" (hash 'en "Phonetic" 'zh-Hant "注音")
        "other" (hash 'en "Other" 'zh-Hant "其他")))

(define catalog-summaries
  (hash "double-pinyin"
        (hash 'en "Compact phonetic systems that trade full syllable spelling for paired initials and finals."
              'zh-Hant "以聲母和韻母配對取代完整拼音的緊湊音碼方案。")
        "full-pinyin"
        (hash 'en "Full Mandarin pinyin systems, useful as the baseline for modern phonetic input."
              'zh-Hant "完整普通話拼音輸入，是現代音碼輸入的基準。")
        "shape"
        (hash 'en "Shape-based methods that encode character structure rather than pronunciation."
              'zh-Hant "依字形結構取碼，而不是依照讀音輸入。")
        "cantonese"
        (hash 'en "Cantonese input methods and dictionaries for Jyutping-style typing."
              'zh-Hant "以粵拼為核心的粵語輸入方案與詞庫。")
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
