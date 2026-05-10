#lang racket/base

(require racket/list
         racket/runtime-path
         "model.rkt"
         "recipes.rkt")

(provide schema-entries
         schema-entry-ref
         schema-entry-ids
         input-method-schema-entries
         input-method-schema-entry-ref
         input-method-schema-entry-ids
         schema-category-order
         schema-category-label
         schema-category-summary)

(define schema-entry-modules
  '("double-pinyin-flypy.rkt"
    "double-pinyin-flypy-14.rkt"
    "double-pinyin-flypy-18.rkt"
    "double-pinyin-flypy-shuffle-17.rkt"
    "luna-pinyin.rkt"
    "terra-pinyin.rkt"
    "pinyin-14.rkt"
    "double-pinyin.rkt"
    "double-pinyin-abc.rkt"
    "double-pinyin-mspy.rkt"
    "double-pinyin-pyjj.rkt"
    "double-pinyin-st.rkt"
    "cangjie5.rkt"
    "cangjie5-express.rkt"
    "cangjie6.rkt"
    "wubi86.rkt"
    "wubi-pinyin.rkt"
    "wubi-trad.rkt"
    "quick5.rkt"
    "stroke.rkt"
    "pinyin-simp.rkt"
    "jyut6ping3.rkt"
    "bopomofo.rkt"))

(define-runtime-path here ".")

(define (module-schema-entry module-file)
  (dynamic-require (build-path here "schema" module-file) 'schema-entry))

(define schema-entries
  (for/list ([module-file (in-list schema-entry-modules)])
    (module-schema-entry module-file)))

(define (schema-entry-ids)
  (map schema-entry-id schema-entries))

(define (input-method-schema-entry-ids)
  (map input-method-recipe-id input-method-recipes))

(define input-method-schema-entries
  (filter (lambda (definition)
            (member (schema-entry-id definition)
                    (input-method-schema-entry-ids)))
          schema-entries))

(define schema-entry-by-id
  (for/hash ([definition (in-list schema-entries)])
    (values (schema-entry-id definition) definition)))

(define (schema-entry-ref id [default #f])
  (hash-ref schema-entry-by-id id default))

(define input-method-schema-entry-ref schema-entry-ref)

(define schema-category-order
  '("double-pinyin" "full-pinyin" "shape" "phonetic" "other"))

(define category-labels
  (hash "double-pinyin" (hash 'en "Double Pinyin" 'zh-Hant "雙拼")
        "full-pinyin" (hash 'en "Full Spelling" 'zh-Hant "全拼")
        "shape" (hash 'en "Shape" 'zh-Hant "字形")
        "phonetic" (hash 'en "Phonetic" 'zh-Hant "注音")
        "other" (hash 'en "Other" 'zh-Hant "其他")))

(define category-summaries
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

(define (schema-category-label category-id [locale 'en])
  (localized-schema-value (hash-ref category-labels category-id #f) locale category-id))

(define (schema-category-summary category-id [locale 'en])
  (localized-schema-value (hash-ref category-summaries category-id #f)
                           locale
                           (localized-schema-value (hash-ref category-summaries "other")
                                                    locale)))
