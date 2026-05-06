#lang racket/base

(require rackunit
         racket/string
         (prefix-in flypy: "../schema/flypy.rkt")
         (prefix-in flypy_14: "../schema/flypy_14.rkt")
         (prefix-in luna_pinyin: "../schema/luna_pinyin.rkt")
         (prefix-in terra_pinyin: "../schema/terra_pinyin.rkt")
         (prefix-in jyut6ping3: "../schema/jyut6ping3.rkt"))

(define (generated-file files path)
  (hash-ref files path (lambda () (error 'generated-file "missing ~a" path))))

(module+ test
  (test-case "flypy shared config emits desktop schema YAML"
    (define yaml (generated-file flypy:config-files "flypy.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: flypy"))
    (check-not-false (string-contains? yaml "name: \"小鶴雙拼\""))
    (check-not-false (string-contains? yaml "dictionary: luna_pinyin"))
    (check-not-false (string-contains? yaml "prism: flypy"))
    (check-equal? flypy:mobile-skins '("flypy")))

  (test-case "flypy ice is a dictionary variant in flypy config"
    (define ice-files (hash-ref flypy:schema-config-files "flypy_ice"))
    (define yaml (generated-file ice-files "flypy_ice.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: flypy_ice"))
    (check-not-false (string-contains? yaml "name: \"小鶴雙拼-霧凇\""))
    (check-not-false (string-contains? yaml "dictionary: rime_ice"))
    (check-not-false (string-contains? yaml "prism: flypy_ice")))

  (test-case "luna pinyin emits desktop schema YAML"
    (define yaml (generated-file luna_pinyin:config-files "luna_pinyin.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: luna_pinyin"))
    (check-not-false (string-contains? yaml "name: \"朙月拼音\""))
    (check-not-false (string-contains? yaml "dictionary: luna_pinyin"))
    (check-not-false (string-contains? yaml "prism: luna_pinyin"))
    (check-equal? luna_pinyin:mobile-skins '("luna_pinyin")))

  (test-case "terra pinyin emits desktop schema YAML"
    (define yaml (generated-file terra_pinyin:config-files "terra_pinyin.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: terra_pinyin"))
    (check-not-false (string-contains? yaml "name: \"地球拼音\""))
    (check-not-false (string-contains? yaml "dictionary: terra_pinyin"))
    (check-not-false (string-contains? yaml "prism: terra_pinyin"))
    (check-equal? terra_pinyin:mobile-skins '("terra_pinyin")))

  (test-case "flypy_14 schema DSL emits stable schema YAML"
    (define yaml (generated-file flypy_14:config-files "flypy_14.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: flypy_14"))
    (check-not-false (string-contains? yaml "name: \"小鶴雙拼-14鍵\""))
    (check-not-false (string-contains? yaml "dependencies:\n    - cangjie6"))
    (check-not-false (string-contains? yaml "alphabet: qetuoadgjlzcbm"))
    (check-not-false (string-contains? yaml "dictionary: rime_ice"))
    (check-not-false (string-contains? yaml "prism: flypy_14")))

  (test-case "custom patch DSL emits direct Rime patch fields"
    (define yaml (generated-file jyut6ping3:config-files "jyut6ping3.custom.yaml"))
    (check-not-false (string-contains? yaml "schema/version: \"0.1\""))
    (check-not-false (string-contains? yaml "recognizer/patterns/punct: \"^/([0-9]0?|[a-z]+)$\""))
    (check-not-false (string-contains? yaml "recognizer/patterns/cangjie6: \"^v[a-z]*;?$\""))))
