#lang racket/base

(require racket/list
         "keyboard.rkt"
         "dsl.rkt"
         "../type.rkt")

(provide (all-from-out "dsl.rkt")
         input-methods
         (struct-out schema-entry)
         (struct-out input-method-recipe)
         input-method-keyboards
         input-method-methods
         input-method-dimensions
         support-schemas
         calculate-input-method-recipes
         input-method-recipes
         support-schema-recipes
         rime-entries
         input-method-recipe-ref
         input-method-recipe-layouts
         input-method-recipe-rime-source-id
         input-method-recipe-rime-config-id
         input-method-recipe-rime-generated?
         input-method-recipe-rime-package?
         input-method-recipe-rime-custom?
         input-method-recipe-rime-deps
         input-method-recipe-rime-extra-files
         input-method-recipe-rime-extra-dirs
         input-method-recipe-rime-artifacts
         rime-schema-ids
         generated-schema-ids
         generated-package-ids
         generated-custom-ids
         generated-config-ids
         extra-schema-ids-with-mobile
         rime-schema-source-id
         rime-schema-config-id
         rime-schema-deps
         rime-schema-extra-files
         rime-schema-extra-dirs
         rime-schema-keyboard-layouts
         rime-schema-artifacts
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

(struct input-method-recipe
  (id
   schema
   keymap
   keyboard
   skeleton
   projection
   legends
   placement
   interactions
   target
   keyboard-layouts
   names
   descriptions
   rime-source-id
   rime-config-id
   rime-generated?
   rime-package?
   rime-custom?
   rime-deps
   rime-extra-files
   rime-extra-dirs
   rime-artifacts)
  #:transparent)

(define input-method-methods
  (filter input-method-dimension? input-methods))

(define input-method-dimensions input-method-methods)

(define input-method-keyboards
  (append-map input-method-dimension-keyboards input-method-dimensions))

(define support-schemas
  (filter support-schema-declaration? input-methods))

(define (input-method-keyboard->recipe method-dimension method-keyboard)
  (define keyboard-dimension
    (keyboard-dimension-ref (input-method-keyboard-keyboard-id method-keyboard)))
  (input-method-recipe
   (input-method-keyboard-recipe-id method-keyboard)
   (input-method-dimension-schema method-dimension)
   (input-method-dimension-keymap method-dimension)
   (input-method-keyboard-keyboard-id method-keyboard)
   (keyboard-dimension-skeleton keyboard-dimension)
   (keyboard-dimension-projection keyboard-dimension)
   (input-method-dimension-legends method-dimension)
   (input-method-keyboard-placement method-keyboard)
   (keyboard-dimension-interactions keyboard-dimension)
   (keyboard-dimension-target keyboard-dimension)
   (list (input-method-keyboard-layout-id method-keyboard))
   (input-method-keyboard-names method-keyboard)
   (input-method-keyboard-descriptions method-keyboard)
   (or (input-method-keyboard-rime-source-id method-keyboard)
       (input-method-keyboard-recipe-id method-keyboard))
   (or (input-method-keyboard-rime-config-id method-keyboard)
       (or (input-method-keyboard-rime-source-id method-keyboard)
           (input-method-keyboard-recipe-id method-keyboard)))
   (input-method-keyboard-rime-generated? method-keyboard)
   (input-method-keyboard-rime-package? method-keyboard)
   (input-method-keyboard-rime-custom? method-keyboard)
   (input-method-keyboard-rime-deps method-keyboard)
   (input-method-keyboard-rime-extra-files method-keyboard)
   (input-method-keyboard-rime-extra-dirs method-keyboard)
   (input-method-keyboard-rime-artifacts method-keyboard)))

(define (calculate-input-method-recipes)
  (append-map
   (lambda (method-dimension)
     (map (lambda (method-keyboard)
            (input-method-keyboard->recipe method-dimension method-keyboard))
          (input-method-dimension-keyboards method-dimension)))
   input-method-dimensions))

(define input-method-recipes
  (calculate-input-method-recipes))

(define (support-schema->recipe definition)
  (input-method-recipe
   (support-schema-declaration-id definition)
   (support-schema-declaration-id definition)
   #f
   #f
   #f
   #f
   '()
   #f
   '()
   'rime
   '()
   #f
   #f
   (support-schema-declaration-source-id definition)
   (or (support-schema-declaration-config-id definition)
       (support-schema-declaration-source-id definition))
   (support-schema-declaration-generated? definition)
   (support-schema-declaration-package? definition)
   (support-schema-declaration-custom? definition)
   (support-schema-declaration-deps definition)
   (support-schema-declaration-extra-files definition)
   (support-schema-declaration-extra-dirs definition)
   (support-schema-declaration-artifacts definition)))

(define support-schema-recipes
  (map support-schema->recipe support-schemas))

(define rime-entries
  (append input-method-recipes support-schema-recipes))

(define input-method-recipe-by-id
  (for/hash ([recipe (in-list rime-entries)])
    (values (input-method-recipe-id recipe) recipe)))

(define (input-method-recipe-ref id [default #f])
  (hash-ref input-method-recipe-by-id id default))

(define (input-method-recipe-layouts id)
  (define recipe (input-method-recipe-ref id #f))
  (if recipe
      (input-method-recipe-keyboard-layouts recipe)
      '()))

(define (rime-schema-ids)
  (map input-method-recipe-id rime-entries))

(define (filter-rime-ids pred?)
  (for/list ([definition (in-list rime-entries)]
             #:when (pred? definition))
    (input-method-recipe-id definition)))

(define generated-schema-ids
  (filter-rime-ids input-method-recipe-rime-generated?))

(define generated-package-ids
  (filter-rime-ids input-method-recipe-rime-package?))

(define generated-custom-ids
  (filter-rime-ids input-method-recipe-rime-custom?))

(define generated-config-ids
  (remove-duplicates (append generated-schema-ids
                             generated-package-ids
                             generated-custom-ids)))

(define extra-schema-ids-with-mobile
  '("bopomofo"))

(define (rime-schema-source-id schema)
  (define definition (input-method-recipe-ref schema #f))
  (if definition
      (input-method-recipe-rime-source-id definition)
      schema))

(define (rime-schema-config-id schema)
  (define definition (input-method-recipe-ref schema #f))
  (if definition
      (input-method-recipe-rime-config-id definition)
      (rime-schema-source-id schema)))

(define (rime-schema-deps schema)
  (define definition (input-method-recipe-ref schema #f))
  (if definition
      (input-method-recipe-rime-deps definition)
      '()))

(define (rime-schema-extra-files schema)
  (define definition (input-method-recipe-ref schema #f))
  (if definition
      (input-method-recipe-rime-extra-files definition)
      '()))

(define (rime-schema-extra-dirs schema)
  (define definition (input-method-recipe-ref schema #f))
  (if definition
      (input-method-recipe-rime-extra-dirs definition)
      '()))

(define (rime-schema-keyboard-layouts schema)
  (define definition (input-method-recipe-ref schema #f))
  (if definition
      (input-method-recipe-keyboard-layouts definition)
      '()))

(define (rime-schema-artifacts schema)
  (define definition (input-method-recipe-ref schema #f))
  (if definition
      (input-method-recipe-rime-artifacts definition)
      '("rime" "yuanshu")))

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
  (for/list ([declaration (in-list input-methods)]
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
