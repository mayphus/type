#lang racket/base

(require racket/list
         "methods.rkt")

(provide (struct-out schema-entry)
         input-method-schema-entry?
         input-method-schema-entry-id
         input-method-schema-entry-category
         input-method-schema-entry-rule
         input-method-schema-entry-deps
         input-method-schema-entry-slug
         input-method-schema-entry-names
         input-method-schema-entry-descriptions
         schema-entries
         schema-entry-ref
         schema-entry-ids
         input-method-schema-entries
         input-method-schema-entry-ref
         input-method-schema-entry-ids
         schema-slug
         schema-display-names
         schema-display-descriptions
         schema-name
         schema-description
         input-method-id?
         schema-category-order
         schema-id->category-id
         schema-category-label
         schema-category-summary)

(struct schema-entry
  (id
   category
   rule
   deps
   slug
   names
   descriptions)
  #:transparent)

(define (make-schema-entry #:id id
                           #:category [category "other"]
                           #:rule [rule category]
                           #:deps [deps '()]
                           #:slug [slug id]
                           #:names [names #f]
                           #:descriptions [descriptions #f])
  (schema-entry id
                category
                rule
                deps
                slug
                names
                descriptions))

(define input-method-schema-entry? schema-entry?)
(define input-method-schema-entry-id schema-entry-id)
(define input-method-schema-entry-category schema-entry-category)
(define input-method-schema-entry-rule schema-entry-rule)
(define input-method-schema-entry-deps schema-entry-deps)
(define input-method-schema-entry-slug schema-entry-slug)
(define input-method-schema-entry-names schema-entry-names)
(define input-method-schema-entry-descriptions schema-entry-descriptions)

(define (localized-schema-value values locale [default #f])
  (cond
    [(hash? values)
     (hash-ref values locale
               (lambda ()
                 (hash-ref values 'en
                           (lambda ()
                             (hash-ref values 'zh-Hant default)))))]
    [else values]))

(define (schema-declaration->entry declaration)
  (make-schema-entry
   #:id (schema-declaration-id declaration)
   #:category (schema-declaration-category declaration)
   #:rule (schema-declaration-rule declaration)
   #:deps (schema-declaration-deps declaration)
   #:slug (schema-declaration-slug declaration)
   #:names (schema-declaration-names declaration)
   #:descriptions (schema-declaration-descriptions declaration)))

(define schema-entries
  (for/list ([declaration (in-list type-catalog)]
             #:when (schema-declaration? declaration))
    (schema-declaration->entry declaration)))

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

(define (schema-slug schema)
  (define definition (schema-entry-ref schema #f))
  (if definition
      (schema-entry-slug definition)
      schema))

(define (schema-display-names schema)
  (define definition (schema-entry-ref schema #f))
  (and definition (schema-entry-names definition)))

(define (schema-display-descriptions schema)
  (define definition (schema-entry-ref schema #f))
  (and definition (schema-entry-descriptions definition)))

(define (schema-name schema [locale 'zh-Hant])
  (localized-schema-value (schema-display-names schema) locale))

(define (schema-description schema [locale 'en])
  (localized-schema-value (schema-display-descriptions schema) locale))

(define (input-method-id? id)
  (and (member id (input-method-schema-entry-ids)) #t))

(define schema-category-order
  '("double-pinyin" "full-pinyin" "shape" "zhuyin" "other"))

(define category-labels
  (hash "double-pinyin" (hash 'en "Double Pinyin" 'zh-Hant "雙拼")
        "full-pinyin" (hash 'en "Full Pinyin" 'zh-Hant "全拼")
        "shape" (hash 'en "Shape" 'zh-Hant "字形")
        "zhuyin" (hash 'en "Zhuyin" 'zh-Hant "注音")
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
        "zhuyin"
        (hash 'en "Mandarin input methods based on Zhuyin symbols rather than Latin pinyin letters."
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

(define (schema-id->category-id id)
  (define definition (schema-entry-ref id #f))
  (if definition
      (schema-entry-category definition)
      "other"))
