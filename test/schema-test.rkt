#lang racket/base

(require rackunit
         json
         racket/list
         racket/runtime-path
         racket/string
         (prefix-in keyboard: "../catalog/keyboard.rkt")
         (prefix-in schema-index: "../catalog/schemas.rkt")
         (prefix-in calculate: "../catalog/methods.rkt")
         (prefix-in rime-catalog: "../catalog/methods.rkt")
         (prefix-in flypy: "../targets/rime/flypy.rkt")
         (prefix-in flypy_14: "../targets/rime/flypy_14.rkt")
         (prefix-in luna_pinyin: "../targets/rime/luna_pinyin.rkt")
         (prefix-in pinyin_14: "../targets/rime/pinyin_14.rkt")
         (prefix-in terra_pinyin: "../targets/rime/terra_pinyin.rkt")
         (prefix-in jyut6ping3: "../targets/rime/jyut6ping3.rkt")
         "../build/main.rkt"
         "../targets/yuanshu/skin/core/preview-svg.rkt"
         "../targets/yuanshu/skin/core/preview.rkt"
         "../targets/yuanshu/skin/layouts/bopomofo-page.rkt"
         (prefix-in flypy14-layout: "../targets/yuanshu/skin/layouts/flypy-14-page.rkt")
         (prefix-in flypy18-layout: "../targets/yuanshu/skin/layouts/flypy-18-page.rkt")
         (prefix-in pinyin14-layout: "../targets/yuanshu/skin/layouts/pinyin-14-page.rkt")
         "../targets/yuanshu/skin/layouts/shuffle-17-pages.rkt"
         "../targets/yuanshu/skin/layouts/standard-phone-pinyin-page.rkt"
         (prefix-in zrm18-layout: "../targets/yuanshu/skin/layouts/zrm-18-page.rkt")
         (prefix-in zrm18-aux-layout: "../targets/yuanshu/skin/layouts/zrm-18-aux-page.rkt"))

(define-runtime-path rime-source-dir "../targets/rime")

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

(define (button-height page id)
  (hash-ref (hash-ref (page-button page id) 'size) 'height #f))

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

(define (visible-preview-row-ids preview row-index)
  (define row (list-ref (hash-ref preview 'rows) row-index))
  (for/list ([key (in-list row)]
             #:when (preview-key-visible? key))
    (hash-ref key 'id)))

(define (svg-height svg)
  (define match (regexp-match #rx"<svg[^>]+height=\"([0-9.]+)\"" svg))
  (and match (string->number (cadr match))))

(define (svg-text? svg text)
  (regexp-match? (regexp (format ">~a</text>" (regexp-quote text))) svg))

(define (svg-key-rect-count svg)
  (length (regexp-match* #rx"<rect[^>]+rx=\"6.00\"" svg)))

(define (layout-item-width layout key-id)
  (hash-ref (layout-item layout key-id) 'width))

(define (layout-item-height layout key-id)
  (hash-ref (layout-item layout key-id) 'height))

(define (layout-item layout key-id)
  (for*/first ([row (in-list layout)]
               [item (in-list row)]
               #:when (equal? (hash-ref (hash-ref item 'key) 'id) key-id))
    item))

(module+ test
  (test-case "schema entry ids are unique"
    (define ids (schema-index:schema-entry-ids))
    (check-equal? (length ids) (length (remove-duplicates ids))))

  (test-case "input-method schema index exposes recipe-backed entries"
    (define recipe-ids
      (map calculate:input-method-recipe-id calculate:input-method-recipes))
    (check-equal? (schema-index:input-method-schema-entry-ids) recipe-ids)
    (check-not-false (member "double-pinyin-flypy" (schema-index:input-method-schema-entry-ids)))
    (check-not-false (member "double-pinyin-flypy-14" (schema-index:input-method-schema-entry-ids)))
    (check-not-false (member "pinyin-14" (schema-index:input-method-schema-entry-ids)))
    (check-false (member "flypy-ice" (schema-index:input-method-schema-entry-ids)))
    (for ([id (in-list (schema-index:input-method-schema-entry-ids))])
      (check-not-false (calculate:input-method-recipe-ref id #f) id)))

  (test-case "schema registry contains only pure schemas"
    (define schema-ids (schema-index:schema-entry-ids))
    (check-not-false (member "double-pinyin-flypy" schema-ids))
    (check-not-false (member "luna-pinyin" schema-ids))
    (for ([id (in-list '("double-pinyin-flypy-14"
                         "double-pinyin-flypy-18"
                         "double-pinyin-flypy-shuffle-17"
                         "pinyin-14"
                         "flypy-ice"))])
      (check-false (member id schema-ids) id)))

  (test-case "keyboard catalog owns reusable keyboard dimensions"
    (check-not-false (keyboard:keyboard-skeleton-definition-ref "standard-26"))
    (check-not-false (keyboard:keyboard-model-definition-ref "standard-26"))
    (check-not-false (keyboard:keyboard-model-definition-ref "compact-14"))
    (check-not-false (keyboard:keyboard-model-definition-ref "compact-18"))
    (check-not-false (keyboard:keyboard-model-definition-ref "compact-17"))
    (check-not-false (keyboard:keyboard-model-definition-ref "zhuyin"))
    (check-not-false (keyboard:keyboard-projection-definition-ref "identity-26"))
    (check-not-false (keyboard:keyboard-projection-definition-ref "adjacent-qwerty-14"))
    (check-not-false (keyboard:keyboard-placement-definition-ref "compact-center"))
    (check-not-false (keyboard:keyboard-interaction-definition-ref "compact-mobile"))
    (check-false (keyboard:keyboard-layout-definition-ref "flypy"))
    (check-false (keyboard:keyboard-layout-definition-ref "missing-layout")))

  (test-case "generated schema entries point at Rime source module files"
    (for ([id (in-list rime-catalog:generated-config-ids)])
      (check-true
       (file-exists?
        (build-path rime-source-dir
                    (string-append (rime-catalog:rime-schema-source-id id)
                                   ".rkt")))
       id)))

  (test-case "schema index keeps dependency and artifact metadata"
    (check-false (member "flypy-ice" (rime-catalog:rime-schema-ids)))
    (check-false (member "flypy_ice" rime-catalog:generated-config-ids))
    (check-equal? (rime-catalog:rime-schema-deps "double-pinyin") '("stroke"))
    (check-equal? (rime-catalog:rime-schema-extra-files "wubi-pinyin") '("wubi86.dict.yaml"))
    (check-equal? (rime-catalog:rime-schema-artifacts "double-pinyin") '("rime" "yuanshu"))
    (check-equal? (rime-catalog:rime-schema-artifacts "bopomofo") '("yuanshu"))
    (check-equal? (schema-index:schema-id->category-id "cangjie6") "shape")
    (check-equal? (schema-index:schema-id->category-id "bopomofo") "zhuyin")
    (check-equal? (schema-index:schema-category-label "full-pinyin" 'en) "Full Pinyin")
    (check-equal? (schema-index:schema-category-label "double-pinyin" 'zh-Hant) "雙拼"))

  (test-case "flypy shared config emits desktop schema YAML"
    (define yaml (generated-file flypy:config-files "flypy.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: flypy"))
    (check-not-false (string-contains? yaml "name: \"小鶴雙拼\""))
    (check-not-false (string-contains? yaml "dictionary: luna_pinyin"))
    (check-not-false (string-contains? yaml "prism: flypy"))
    (check-equal? flypy:keyboard-layouts '("flypy")))

  (test-case "flypy skin preview includes flypy legends"
    (define flypy-layout-module
      (for/first ([item (in-list (list-keyboard-layout-items rime-catalog:generated-config-ids))]
                  #:when (equal? (cadr item) "flypy"))
        (caddr item)))
    (define preview
      (keyboard-layout-module-ref flypy-layout-module 'keyboard-layout-preview-spec))
    (define q-key (preview-key preview "qButton"))
    (check-not-false q-key)
    (check-true
     (for/or ([layer (in-list (hash-ref q-key 'layers))])
       (equal? (hash-ref layer 'text) "iu"))))

  (test-case "generated Yuanshu layouts do not emit swipe-down actions"
    (for* ([item (in-list (list-keyboard-layout-items rime-catalog:generated-config-ids))]
           [files (in-value ((keyboard-layout-module-ref (caddr item)
                                                         'keyboard-layout-files-with-docs)))]
           [(path content) (in-hash files)]
           #:when (regexp-match? #rx"[.]yaml$" path))
      (check-false (string-contains? content "swipeDownAction")
                   (format "~a should not contain swipeDownAction" path))))

  (test-case "luna pinyin emits desktop schema YAML"
    (define yaml (generated-file luna_pinyin:config-files "luna_pinyin.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: luna_pinyin"))
    (check-not-false (string-contains? yaml "name: \"朙月拼音\""))
    (check-not-false (string-contains? yaml "dictionary: luna_pinyin"))
    (check-not-false (string-contains? yaml "prism: luna_pinyin"))
    (check-equal? luna_pinyin:keyboard-layouts '("luna_pinyin")))

  (test-case "terra pinyin emits desktop schema YAML"
    (define yaml (generated-file terra_pinyin:config-files "terra_pinyin.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: terra_pinyin"))
    (check-not-false (string-contains? yaml "name: \"地球拼音\""))
    (check-not-false (string-contains? yaml "dictionary: terra_pinyin"))
    (check-not-false (string-contains? yaml "prism: terra_pinyin"))
    (check-equal? terra_pinyin:keyboard-layouts '("terra_pinyin")))

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
    (check-false (button-height page "strokeHButton"))
    (check-equal? (button-width page "strokeZButton") "113.5/1125")
    (check-false (button-height page "strokeZButton"))
    (check-equal? (button-width page "spaceButton") "267.5/1125"))

  (test-case "shuffle_17 preview hides punctuation control row"
    (define preview (preview-spec-from-files shuffle-17-pinyin-files))
    (check-equal? (length (hash-ref preview 'rows)) 4)
    (check-equal? (length (filter preview-key-visible?
                                  (list-ref (hash-ref preview 'rows) 3)))
                  0))

  (test-case "only shuffle_17 and bopomofo keep custom phone last rows"
    (define standard-last-row
      '("numericButton" "emojiButton" "spaceButton" "semicolonButton" "enterButton"))
    (for ([files (in-list (list flypy14-layout:flypy-14-iphone-pinyin-files
                                pinyin14-layout:pinyin-14-iphone-pinyin-files
                                flypy18-layout:flypy-18-iphone-pinyin-files
                                zrm18-layout:zrm-18-iphone-pinyin-files
                                zrm18-aux-layout:zrm-18-aux-iphone-pinyin-files))])
      (define page (generated-json files "light/pinyinPortrait.yaml"))
      (check-equal? (layout-row-cell-ids page 3) standard-last-row))
    (check-equal? (layout-row-cell-ids (generated-json shuffle-17-pinyin-files
                                                       "light/pinyinPortrait.yaml")
                                       3)
                  '("strokeHButton" "strokeSButton" "strokePButton" "strokeNButton"
                    "strokeZButton" "spaceButton" "numericButton" "enterButton"))
    (check-equal? (layout-row-cell-ids (generated-json bopomofo-pinyin-files
                                                       "light/pinyinPortrait.yaml")
                                       4)
                  '("numericButton" "emojiButton" "spaceButton" "backspaceButton"
                    "enterButton")))

  (test-case "flypy_14 schema DSL emits stable schema YAML"
    (define yaml (generated-file flypy_14:config-files "flypy_14.schema.yaml"))
    (check-not-false (string-contains? yaml "schema_id: flypy_14"))
    (check-not-false (string-contains? yaml "name: \"小鶴雙拼 14鍵\""))
    (check-not-false (string-contains? yaml "dependencies:\n    - cangjie6"))
    (check-not-false (string-contains? yaml "alphabet: qetuoadgjlzcbm"))
    (check-not-false (string-contains? yaml "dictionary: luna_pinyin"))
    (check-not-false (string-contains? yaml "prism: flypy_14")))

  (test-case "14-key schemas own their layout definitions"
    (check-equal? flypy_14:keyboard-layouts '("flypy_14"))
    (check-equal? pinyin_14:keyboard-layouts '("pinyin_14"))
    (check-not-false (assoc "flypy_14" flypy_14:keyboard-layout-defs))
    (check-not-false (assoc "pinyin_14" pinyin_14:keyboard-layout-defs))
    (check-false (keyboard:keyboard-layout-definition-ref "flypy_14"))
    (check-false (keyboard:keyboard-layout-definition-ref "pinyin_14")))

  (test-case "14-key third row uses five equal-width buttons"
    (for ([files (in-list (list flypy14-layout:flypy-14-iphone-pinyin-files
                                pinyin14-layout:pinyin-14-iphone-pinyin-files))])
      (define page (generated-json files "light/pinyinPortrait.yaml"))
      (check-equal? (layout-row-cell-ids page 2)
                    '("zx14Button" "cv14Button" "bn14Button" "m14Button"
                      "backspaceButton"))
      (for ([button-id (in-list '("qw14Button" "as14Button" "zx14Button"
                                  "cv14Button" "bn14Button" "m14Button"
                                  "backspaceButton"))])
        (check-equal? (button-width page button-id) "225/1125")
        (check-false (button-height page button-id)))
      (define preview (preview-spec-from-files files))
      (check-equal? (visible-preview-row-ids preview 2)
                    '("zx14Button" "cv14Button" "bn14Button" "m14Button"))))

  (test-case "full pinyin 14-key keyboard layout leaves bottom detail labels blank"
    (define page (generated-json pinyin14-layout:pinyin-14-iphone-pinyin-files
                                 "light/pinyinPortrait.yaml"))
    (define flypy-page (generated-json flypy14-layout:flypy-14-iphone-pinyin-files
                                       "light/pinyinPortrait.yaml"))
    (check-equal? (hash-ref (hash-ref page 'qw14ButtonDetailForegroundStyle) 'text) "")
    (check-equal? (hash-ref (hash-ref (hash-ref page 'qw14ButtonMainForegroundStyle) 'center) 'y)
                  0.5)
    (check-equal? (hash-ref (hash-ref flypy-page 'qw14ButtonDetailForegroundStyle) 'text)
                  "iu ei ia ua")
    (check-equal? (hash-ref (hash-ref (hash-ref flypy-page 'qw14ButtonMainForegroundStyle) 'center) 'y)
                  0.5))

  (test-case "shape keyboard layout uses default abc-sized primary glyphs"
    (define luna-layout-module
      (schema-keyboard-layout-module-path "luna_pinyin" '("luna_pinyin")))
    (define cangjie-layout-module
      (schema-keyboard-layout-module-path "cangjie6" '("cangjie6")))
    (define luna-phone
      (generated-json (keyboard-layout-module-ref luna-layout-module
                                                  'keyboard-layout-files)
                      "light/pinyinPortrait.yaml"))
    (define cangjie-phone
      (generated-json (keyboard-layout-module-ref cangjie-layout-module
                                                  'keyboard-layout-files)
                      "light/pinyinPortrait.yaml"))
    (define luna-ipad
      (generated-json (keyboard-layout-module-ref luna-layout-module
                                                  'keyboard-layout-files)
                      "light/iPadPinyinPortrait.yaml"))
    (define cangjie-ipad
      (generated-json (keyboard-layout-module-ref cangjie-layout-module
                                                  'keyboard-layout-files)
                      "light/iPadPinyinPortrait.yaml"))
    (check-equal?
     (hash-ref (hash-ref cangjie-phone 'aButtoncangjie6ForegroundStyle) 'fontSize)
     (hash-ref (hash-ref luna-phone 'aButtonAbcForegroundStyle) 'fontSize))
    (check-equal?
     (hash-ref (hash-ref cangjie-phone 'aButtoncangjie6ForegroundStyle) 'fontWeight #f)
     #f)
    (check-equal?
     (hash-ref (hash-ref cangjie-ipad 'aButtoncangjie6ForegroundStyle) 'fontSize)
     (hash-ref (hash-ref luna-ipad 'aButtonUppercaseForegroundStyle) 'fontSize))
    (check-equal?
     (hash-ref (hash-ref cangjie-ipad 'aButtoncangjie6ForegroundStyle) 'fontWeight #f)
     #f)
    (check-equal? (rime-catalog:rime-schema-keyboard-layouts "quick5") '("cangjie5"))
    (check-equal? (rime-catalog:rime-schema-keyboard-layouts "cangjie5") '("cangjie5")))

  (test-case "keyboard legends live in keymap catalog through keyboard facade"
    (check-equal? (keyboard:keyboard-legend-text 'wubi 'q) "金/勹")
    (check-equal? (keyboard:keyboard-legend-text 'jyutping 'a) "aa/a")
    (check-equal? (keyboard:keyboard-legend-text 'missing 'q) ""))

  (test-case "static upstream schemas resolve dedicated legend keyboard layouts"
    (define (layout-page schema layout)
      (define module (schema-keyboard-layout-module-path layout (list schema)))
      (check-not-false module)
      (generated-json (keyboard-layout-module-ref module 'keyboard-layout-files)
                      "light/pinyinPortrait.yaml"))
    (define wubi-page (layout-page "wubi86" "wubi86"))
    (define stroke-page (layout-page "stroke" "stroke"))
    (define cangjie5-page (layout-page "cangjie5" "cangjie5"))
    (define zrm-page (layout-page "double_pinyin" "double_pinyin_zrm"))
    (define abc-page (layout-page "double_pinyin_abc" "double_pinyin_abc"))
    (check-equal? (hash-ref (hash-ref wubi-page 'qButtonwubiForegroundStyle) 'text)
                  "金/勹")
    (check-equal? (hash-ref (hash-ref stroke-page 'hButtonstrokeForegroundStyle) 'text)
                  "一")
    (check-equal? (hash-ref (hash-ref cangjie5-page 'hButtoncangjie5ForegroundStyle) 'text)
                  "竹")
    (check-equal? (hash-ref (hash-ref cangjie5-page 'xButtoncangjie5ForegroundStyle) 'text)
                  "難")
    (check-equal? (hash-ref (hash-ref cangjie5-page 'zButtoncangjie5ForegroundStyle) 'text)
                  "符")
    (check-equal? (hash-ref (hash-ref zrm-page 'qButtonzrmForegroundStyle) 'text)
                  "iu")
    (check-equal? (hash-ref (hash-ref abc-page 'aButtonabcdpForegroundStyle) 'text)
                  "zh"))

  (test-case "jyutping keyboard layout includes Cantonese spelling legends"
    (define jyutping-layout-module
      (schema-keyboard-layout-module-path "jyut6ping3" '("jyut6ping3")))
    (define page
      (generated-json (keyboard-layout-module-ref jyutping-layout-module
                                                  'keyboard-layout-files)
                      "light/pinyinPortrait.yaml"))
    (check-equal? (hash-ref (hash-ref page 'aButtonjyutpingForegroundStyle) 'text)
                  "aa/a")
    (check-equal? (hash-ref (hash-ref page 'gButtonjyutpingForegroundStyle) 'text)
                  "g/gw")
    (check-equal? (hash-ref (hash-ref page 'qButtonjyutpingForegroundStyle) 'text)
                  "—"))

  (test-case "standard phone middle and z rows keep real key widths"
    (define files (make-flypy-phone-files standard-phone-base-for-test))
    (define page (generated-json files "light/pinyinPortrait.yaml"))
    (check-equal? (layout-row-cell-ids page 1)
                  '("middleRowLeftSpacer"
                    "aButton" "sButton" "dButton" "fButton" "gButton"
                    "hButton" "jButton" "kButton" "lButton"
                    "middleRowRightSpacer"))
    (check-equal? (layout-row-cell-ids page 2)
                  '("shiftButton" "thirdRowLeftSpacer"
                    "zButton" "xButton" "cButton" "vButton"
                    "bButton" "nButton" "mButton"
                    "thirdRowRightSpacer" "backspaceButton"))
    (check-equal? (button-width page "qButton") "112.5/1125")
    (check-false (button-height page "qButton"))
    (check-equal? (button-width page "aButton") "112.5/1125")
    (check-false (button-height page "aButton"))
    (check-equal? (button-width page "lButton") "112.5/1125")
    (check-false (button-height page "lButton"))
    (check-equal? (button-width page "spaceButton") "475/1125")
    (check-false (hash-ref (page-button page "aButton") 'bounds #f))
    (check-false (hash-ref (page-button page "lButton") 'bounds #f))
    (check-equal? (button-width page "middleRowLeftSpacer") "56.25/1125")
    (check-equal? (button-width page "middleRowRightSpacer") "56.25/1125")
    (check-equal? (button-width page "thirdRowLeftSpacer") "56.25/1125")
    (check-equal? (button-width page "thirdRowRightSpacer") "56.25/1125"))

  (test-case "phone skin keeps compact square typing geometry available"
    (define files (make-flypy-phone-files standard-phone-base-for-test))
    (define page (generated-json files "light/pinyinPortrait.yaml"))
    (define preview (preview-spec-from-files files))
    (define standard-key-side
      (hash-ref (first (first (preview-layout preview))) 'width))
    (define standard-svg-height (svg-height (keyboard-preview-svg preview)))
    (check-equal? (hash-ref preview 'source) 'dsl)
    (check-equal? (hash-ref preview 'key-shape) 'square)
    (check-equal? (hash-ref preview 'visible-keys) 'typing)
    (check-equal? (hash-ref (hash-ref page 'alphabeticButtonBackgroundStyle)
                            'cornerRadius)
                  6)
    (for* ([row (in-list (preview-layout preview))]
           [item (in-list row)])
      (check-equal? (hash-ref item 'width)
                    (hash-ref item 'height)))
    (check-true (< standard-svg-height 216))
    (for ([compact-preview
           (in-list (list (preview-spec-from-files flypy14-layout:flypy-14-iphone-pinyin-files)
                          (preview-spec-from-files flypy18-layout:flypy-18-iphone-pinyin-files)
                          (preview-spec-from-files shuffle-17-pinyin-files)))])
      (check-equal? (hash-ref (first (first (preview-layout compact-preview))) 'width)
                    standard-key-side)
      (check-equal? (svg-height (keyboard-preview-svg compact-preview))
                    standard-svg-height)))

  (test-case "web preview keeps compact layout while demo reads Yuanshu skin shape"
    (define files (make-flypy-phone-files standard-phone-base-for-test))
    (define preview (preview-spec-from-files files))
    (define web-svg (hash-ref (preview-spec->svgs preview) 'light))
    (define skin-svg (keyboard-skin-preview-svg preview))
    (define demo-svg (demo-preview-svg "Flypy" preview))
    (define skin-layout (preview-layout preview #:geometry 'skin-proportional))
    (check-equal? (svg-height web-svg)
                  (svg-height (keyboard-preview-svg preview)))
    (check-true (> (layout-item-height skin-layout "qButton")
                   (layout-item-width skin-layout "qButton")))
    (check-false (svg-text? web-svg "space"))
    (check-false (svg-text? web-svg "123"))
    (check-true (svg-text? demo-svg "123"))
    (check-true (string-contains? demo-svg skin-svg))
    (check-true (> (svg-key-rect-count demo-svg)
                   (svg-key-rect-count web-svg)))
    (check-true (> (svg-height demo-svg)
                   (svg-height web-svg))))

  (test-case "demo image layout follows real Yuanshu key width weights"
    (define files (make-flypy-phone-files standard-phone-base-for-test))
    (define preview (hash-set (preview-spec-from-files files) 'visible-keys 'all))
    (define web-layout (preview-layout preview))
    (define skin-layout (preview-layout preview #:geometry 'skin-proportional))
    (check-equal? (layout-item-width web-layout "spaceButton")
                  (layout-item-width web-layout "numericButton"))
    (check-true (> (layout-item-width skin-layout "spaceButton")
                   (layout-item-width skin-layout "numericButton")))
    (check-true (< (layout-item-width skin-layout "spaceButton")
                   (* 5 (layout-item-width skin-layout "qButton"))))
    (define last-row (last skin-layout))
    (check-= (hash-ref (first last-row) 'x) 8 0.001)
    (check-= (+ (hash-ref (last last-row) 'x)
                (hash-ref (last last-row) 'width))
             367
             0.001)
    (check-true (> (layout-item-width skin-layout "backspaceButton")
                   (layout-item-width skin-layout "zButton"))))

  (test-case "DSL note positions expand to square-key regions"
    (define flypy-page (generated-json (make-flypy-phone-files standard-phone-base-for-test)
                                       "light/pinyinPortrait.yaml"))
    (define luna-layout-module
      (schema-keyboard-layout-module-path "luna_pinyin" '("luna_pinyin")))
    (define luna-page (generated-json (keyboard-layout-module-ref luna-layout-module
                                                                  'keyboard-layout-files)
                                      "light/pinyinPortrait.yaml"))
    (check-equal? (hash-ref (hash-ref (hash-ref flypy-page 'qButtonAbcForegroundStyle)
                                      'center)
                            'y)
                  0.24)
    (check-equal? (hash-ref (hash-ref (hash-ref flypy-page 'qButtonFlypyBottomForegroundStyle)
                                      'center)
                            'y)
                  0.68)
    (check-equal? (hash-ref (hash-ref (hash-ref luna-page 'qButtonAbcForegroundStyle)
                                      'center)
                            'y)
                  0.5))

  (test-case "phone preview hides layout spacers"
    (define files (make-flypy-phone-files standard-phone-base-for-test))
    (define preview (preview-spec-from-files files))
    (check-equal? (visible-preview-row-ids preview 1)
                  '("aButton" "sButton" "dButton" "fButton" "gButton"
                    "hButton" "jButton" "kButton" "lButton"))
    (check-equal? (visible-preview-row-ids preview 2)
                  '("zButton" "xButton" "cButton" "vButton"
                    "bButton" "nButton" "mButton")))

  (test-case "custom patch DSL emits direct Rime patch fields"
    (define yaml (generated-file jyut6ping3:config-files "jyut6ping3.custom.yaml"))
    (check-not-false (string-contains? yaml "schema/version: \"0.1\""))
    (check-not-false (string-contains? yaml "recognizer/patterns/punct: \"^/([0-9]0?|[a-z]+)$\""))
    (check-not-false (string-contains? yaml "recognizer/patterns/cangjie6: \"^v[a-z]*;?$\""))))
