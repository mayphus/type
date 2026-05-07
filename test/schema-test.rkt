#lang racket/base

(require rackunit
         json
         racket/list
         racket/string
         (prefix-in flypy: "../schema/flypy.rkt")
         (prefix-in flypy_14: "../schema/flypy_14.rkt")
         (prefix-in luna_pinyin: "../schema/luna_pinyin.rkt")
         (prefix-in terra_pinyin: "../schema/terra_pinyin.rkt")
         (prefix-in jyut6ping3: "../schema/jyut6ping3.rkt")
         "../schema/lib/mobile/core/preview.rkt"
         "../schema/lib/mobile/layouts/bopomofo-page.rkt"
         (prefix-in flypy14-layout: "../schema/lib/mobile/layouts/flypy-14-page.rkt")
         (prefix-in pinyin14-layout: "../schema/lib/mobile/layouts/pinyin-14-page.rkt")
         "../schema/lib/mobile/layouts/shuffle-17-pages.rkt"
         "../schema/lib/mobile/layouts/standard-phone-pinyin-page.rkt")

(define (generated-file files path)
  (hash-ref files path (lambda () (error 'generated-file "missing ~a" path))))

(define (standard-phone-base-for-test dark? portrait?)
  (cond
    [(and dark? portrait?) standard-phone-portrait-dark-base]
    [(and dark? (not portrait?)) standard-phone-landscape-dark-base]
    [(and (not dark?) portrait?) standard-phone-portrait-light-base]
    [else standard-phone-landscape-light-base]))

(define (generated-json files path)
  (bytes->jsexpr (string->bytes/utf-8 (generated-file files path))))

(define (page-button page id)
  (hash-ref page (string->symbol id)))

(define (button-width page id)
  (hash-ref (hash-ref (page-button page id) 'size) 'width))

(define (layout-row-cell-ids page row-index)
  (define row (list-ref (hash-ref page 'keyboardLayout) row-index))
  (define subviews (hash-ref (hash-ref row 'HStack) 'subviews))
  (for/list ([subview (in-list subviews)])
    (hash-ref subview 'Cell)))

(define (preview-key preview id)
  (for*/first ([row (in-list (hash-ref preview 'rows))]
               [key (in-list row)]
               #:when (equal? (hash-ref key 'id) id))
    key))

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

  (test-case "bopomofo shares er with an instead of adding a fourth-row key"
    (define page (generated-json bopomofo-pinyin-files "light/pinyinPortrait.yaml"))
    (check-equal? (layout-row-cell-ids page 3)
                  '("foButton" "leButton" "heButton" "xiButton" "riButton"
                    "siButton" "yuButton" "ehButton" "ouButton" "engButton"))
    (check-false (hash-has-key? page 'erButton))
    (check-equal? (hash-ref (hash-ref (page-button page "anButton") 'action) 'character) "0")
    (check-equal? (hash-ref (hash-ref (page-button page "anButton") 'swipeUpAction) 'character) "-")
    (check-equal? (button-width page "engButton") "112.5/1125"))

  (test-case "bopomofo delete key is wide enough for the icon"
    (define page (generated-json bopomofo-pinyin-files "light/pinyinPortrait.yaml"))
    (check-equal? (button-width page "backspaceButton") "300/1125"))

  (test-case "bopomofo emoji key is wide enough for the icon"
    (define page (generated-json bopomofo-pinyin-files "light/pinyinPortrait.yaml"))
    (define preview (preview-spec-from-files bopomofo-pinyin-files))
    (check-equal? (button-width page "emojiButton") "150/1125")
    (check-equal? (hash-ref (hash-ref page 'emojiButtonForegroundStyle) 'fontSize) 22)
    (check-equal? (hash-ref (preview-key preview "emojiButton") 'icon-size) 22))

  (test-case "bopomofo search key matches standard phone width"
    (define page (generated-json bopomofo-pinyin-files "light/pinyinPortrait.yaml"))
    (check-equal? (button-width page "enterButton") "280/1125"))

  (test-case "shuffle_17 phone space gives width to symbol keys"
    (define page (generated-json shuffle-17-pinyin-files "light/pinyinPortrait.yaml"))
    (check-equal? (button-width page "strokeHButton") "113.5/1125")
    (check-equal? (button-width page "strokeZButton") "113.5/1125")
    (check-equal? (button-width page "spaceButton") "267.5/1125"))

  (test-case "flypy_14 schema DSL emits stable schema YAML"
    (define yaml (generated-file flypy_14:config-files "flypy_14.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: flypy_14"))
    (check-not-false (string-contains? yaml "name: \"小鶴雙拼-14鍵\""))
    (check-not-false (string-contains? yaml "dependencies:\n    - cangjie6"))
    (check-not-false (string-contains? yaml "alphabet: qetuoadgjlzcbm"))
    (check-not-false (string-contains? yaml "dictionary: rime_ice"))
    (check-not-false (string-contains? yaml "prism: flypy_14")))

  (test-case "14-key third row keeps backspace same width as shift"
    (for ([files (in-list (list flypy14-layout:flypy-14-iphone-pinyin-files
                                pinyin14-layout:pinyin-14-iphone-pinyin-files))])
      (define page (generated-json files "light/pinyinPortrait.yaml"))
      (check-equal? (layout-row-cell-ids page 2)
                    '("thirdRowLeftSpacer"
                      "shiftButton" "zx14Button" "cv14Button" "bn14Button" "m14Button"
                      "backspaceButton"
                      "thirdRowRightSpacer"))
      (check-equal? (button-width page "shiftButton") "160/1125")
      (check-equal? (button-width page "backspaceButton") "160/1125")
      (check-equal? (button-width page "thirdRowLeftSpacer") "82.5/1125")
      (check-equal? (button-width page "thirdRowRightSpacer") "82.5/1125")
      (define preview (preview-spec-from-files files))
      (define third-row (third (hash-ref preview 'rows)))
      (check-equal? (map (lambda (key) (hash-ref key 'id)) third-row)
                    '("shiftButton" "zx14Button" "cv14Button" "bn14Button" "m14Button"
                      "backspaceButton"))))

  (test-case "standard phone middle row keeps real key widths"
    (define files (make-flypy-phone-files standard-phone-base-for-test))
    (define page (generated-json files "light/pinyinPortrait.yaml"))
    (check-equal? (layout-row-cell-ids page 1)
                  '("middleRowLeftSpacer"
                    "aButton" "sButton" "dButton" "fButton" "gButton"
                    "hButton" "jButton" "kButton" "lButton"
                    "middleRowRightSpacer"))
    (check-equal? (button-width page "qButton") "112.5/1125")
    (check-equal? (button-width page "aButton") "112.5/1125")
    (check-equal? (button-width page "lButton") "112.5/1125")
    (check-false (hash-ref (page-button page "aButton") 'bounds #f))
    (check-false (hash-ref (page-button page "lButton") 'bounds #f))
    (check-equal? (button-width page "middleRowLeftSpacer") "56.25/1125")
    (check-equal? (button-width page "middleRowRightSpacer") "56.25/1125"))

  (test-case "phone preview hides middle row layout spacers"
    (define files (make-flypy-phone-files standard-phone-base-for-test))
    (define preview (preview-spec-from-files files))
    (define middle-row (second (hash-ref preview 'rows)))
    (check-equal? (map (lambda (key) (hash-ref key 'id)) middle-row)
                  '("aButton" "sButton" "dButton" "fButton" "gButton"
                    "hButton" "jButton" "kButton" "lButton")))

  (test-case "custom patch DSL emits direct Rime patch fields"
    (define yaml (generated-file jyut6ping3:config-files "jyut6ping3.custom.yaml"))
    (check-not-false (string-contains? yaml "schema/version: \"0.1\""))
    (check-not-false (string-contains? yaml "recognizer/patterns/punct: \"^/([0-9]0?|[a-z]+)$\""))
    (check-not-false (string-contains? yaml "recognizer/patterns/cangjie6: \"^v[a-z]*;?$\""))))
