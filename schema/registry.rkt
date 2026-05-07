#lang racket/base

(require racket/list)

(provide generated-schema-ids
         generated-custom-ids
         generated-config-ids
         extra-schema-ids-with-mobile
         schema-source-id
         schema-catalog-order
         schema-id->catalog-id
         schema-catalog-label)

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

(define (schema-catalog-label catalog-id)
  (hash-ref (hash "double-pinyin" "Double Pinyin"
                  "full-pinyin" "Full Pinyin"
                  "shape" "Shape"
                  "cantonese" "Cantonese"
                  "phonetic" "Phonetic"
                  "other" "Other")
            catalog-id
            catalog-id))
