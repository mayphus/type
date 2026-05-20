#lang racket/base

(require racket/list
         "../keyboard/dimensions.rkt")

(provide (struct-out input-method-recipe)
         (struct-out input-method-dimension)
         input-method-keyboards
         input-method-dimensions
         calculate-input-method-recipes
         input-method-recipes
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
         input-method-recipe-rime-artifacts)

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

(struct input-method-keyboard
  (recipe-id
   keyboard-id
   layout-id
   placement
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

(struct input-method-dimension
  (id
   schema
   keymap
   legends
   keyboards)
  #:transparent)

(define (localized en zh)
  (hash 'en en 'zh-Hant zh))

(define (keyboard recipe-id
                  keyboard-id
                  layout-id
                  placement
                  #:en-name [en-name #f]
                  #:zh-name [zh-name #f]
                  #:en-description [en-description #f]
                  #:zh-description [zh-description #f]
                  #:rime-source-id [rime-source-id #f]
                  #:rime-config-id [rime-config-id #f]
                  #:rime-generated? [rime-generated? #f]
                  #:rime-package? [rime-package? #f]
                  #:rime-custom? [rime-custom? #f]
                  #:rime-deps [rime-deps '()]
                  #:rime-extra-files [rime-extra-files '()]
                  #:rime-extra-dirs [rime-extra-dirs '()]
                  #:rime-artifacts [rime-artifacts '("rime" "yuanshu")])
  (input-method-keyboard recipe-id
                         keyboard-id
                         layout-id
                         placement
                         (and en-name zh-name (localized en-name zh-name))
                         (and en-description zh-description
                              (localized en-description zh-description))
                         rime-source-id
                         rime-config-id
                         rime-generated?
                         rime-package?
                         rime-custom?
                         rime-deps
                         rime-extra-files
                         rime-extra-dirs
                         rime-artifacts))

(define (method id
                #:schema [schema id]
                #:keymap [keymap id]
                #:legends [legends '()]
                #:keyboards keyboards)
  (input-method-dimension id schema keymap legends keyboards))

(define input-method-dimensions
  (list
   (method "double-pinyin-flypy"
           #:schema "double-pinyin-flypy"
           #:keymap 'flypy
           #:legends '(abc flypy)
           #:keyboards
           (list
            (keyboard "double-pinyin-flypy" 'standard-26 "flypy" 'split-flypy
                      #:rime-source-id "flypy"
                      #:rime-config-id "flypy"
                      #:rime-generated? #t
                      #:rime-custom? #t)
            (keyboard "double-pinyin-flypy-14" 'compact-14 "flypy_14" 'compact-center
                      #:en-name "Flypy 14"
                      #:zh-name "小鶴雙拼 14鍵"
                      #:en-description "A 14-key Flypy double pinyin input method for Yuanshu, grouping adjacent QWERTY keys."
                      #:zh-description "14 鍵小鶴元書輸入法，按相鄰 QWERTY 鍵位分組。"
                      #:rime-source-id "flypy_14"
                      #:rime-generated? #t)
            (keyboard "double-pinyin-flypy-18" 'compact-18 "flypy_18" 'compact-center
                      #:en-name "Flypy 18"
                      #:zh-name "小鶴雙拼 18鍵"
                      #:en-description "An 18-key Flypy double pinyin input method for Yuanshu, adapted from a compact phone layout."
                      #:zh-description "18 鍵小鶴元書輸入法，改編自緊湊手機鍵盤佈局。"
                      #:rime-source-id "flypy_18"
                      #:rime-generated? #t)
            (keyboard "double-pinyin-flypy-shuffle-17" 'shuffle-17 "shuffle_17" 'compact-center
                      #:en-name "Flypy Shuffle 17"
                      #:zh-name "小鶴雙拼亂序 17鍵"
                      #:en-description "An experimental 17-key shuffled Flypy input method for Yuanshu."
                      #:zh-description "實驗性的 17 鍵亂序小鶴元書輸入法。"
                      #:rime-source-id "shuffle_17"
                      #:rime-generated? #t)))
   (method "luna-pinyin"
           #:schema "luna-pinyin"
           #:keymap 'abc
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "luna-pinyin" 'standard-26 "luna_pinyin" 'standard-center
                      #:rime-source-id "luna_pinyin"
                      #:rime-generated? #t)
            (keyboard "pinyin-14" 'compact-14 "pinyin_14" 'compact-center
                      #:en-name "Pinyin 14-Key"
                      #:zh-name "朙月拼音-14鍵"
                      #:en-description "A 14-key full-pinyin Yuanshu input method using adjacent QWERTY groups."
                      #:zh-description "14 鍵全拼元書輸入法，使用相鄰 QWERTY 分組。"
                      #:rime-source-id "pinyin_14"
                      #:rime-generated? #t)))
   (method "terra-pinyin"
           #:schema "terra-pinyin"
           #:keymap 'abc
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "terra-pinyin" 'standard-26 "terra_pinyin" 'standard-center
                      #:rime-source-id "terra_pinyin"
                      #:rime-generated? #t)))
   (method "cangjie6"
           #:keymap 'cangjie
           #:legends '(cangjie)
           #:keyboards
           (list
            (keyboard "cangjie6" 'standard-26 "cangjie6" 'standard-center
                      #:rime-generated? #t
                      #:rime-custom? #t
                      #:rime-deps '("double-pinyin-flypy"))
            (keyboard "cangjie5" 'standard-26 "cangjie6" 'standard-center
                      #:rime-deps '("luna-pinyin")
                      #:rime-extra-files '("cangjie5.dict.yaml"))
            (keyboard "cangjie5-express" 'standard-26 "cangjie6" 'standard-center
                      #:rime-source-id "cangjie5_express"
                      #:rime-deps '("luna-pinyin")
                      #:rime-extra-files '("cangjie5.dict.yaml"))
            (keyboard "quick5" 'standard-26 "cangjie6" 'standard-center
                      #:rime-deps '("luna-pinyin")
                      #:rime-extra-files '("quick5.dict.yaml"))))
   (method "jyut6ping3"
           #:keymap 'jyutping
           #:legends '(abc jyutping)
           #:keyboards
           (list
            (keyboard "jyut6ping3" 'standard-26 "jyut6ping3" 'standard-top-center
                      #:rime-generated? #t
                      #:rime-custom? #t
                      #:rime-deps '("double-pinyin-flypy" "cangjie6"))))
   (method "bopomofo"
           #:keymap 'zhuyin
           #:legends '(zhuyin)
           #:keyboards
           (list
            (keyboard "bopomofo-standard" 'standard-zhuyin "bopomofo_standard" 'standard-center
                      #:en-name "Bopomofo Standard"
                      #:zh-name "標準注音"
                      #:en-description "Zhuyin input on the standard Da-Chien physical keyboard."
                      #:zh-description "使用標準大千式實體鍵盤排列的注音輸入法。"
                      #:rime-source-id "bopomofo-standard"
                      #:rime-config-id "bopomofo"
                      #:rime-extra-files '("terra_pinyin.dict.yaml" "zhuyin.yaml")
                      #:rime-artifacts '("rime"))
            (keyboard "bopomofo" 'zhuyin "bopomofo" 'standard-center
                      #:en-name "Ortholinear Bopomofo"
                      #:zh-name "正交注音"
                      #:en-description "Zhuyin input arranged on an ortholinear mobile keyboard."
                      #:zh-description "配置為正交手機鍵盤的注音輸入法。"
                      #:rime-generated? #t
                      #:rime-artifacts '("yuanshu"))))
   (method "double-pinyin"
           #:schema "double-pinyin"
           #:keymap 'zrm
           #:legends '(abc zrm)
           #:keyboards
           (list
            (keyboard "double-pinyin" 'standard-26 "double_pinyin_zrm" 'double-pinyin-center
                      #:rime-source-id "double_pinyin"
                      #:rime-deps '("stroke"))))
   (method "double-pinyin-abc"
           #:schema "double-pinyin-abc"
           #:keymap 'abc-dp
           #:legends '(abc abc-dp)
           #:keyboards
           (list
            (keyboard "double-pinyin-abc" 'standard-26 "double_pinyin_abc" 'double-pinyin-center
                      #:rime-source-id "double_pinyin_abc"
                      #:rime-deps '("stroke"))))
   (method "double-pinyin-mspy"
           #:schema "double-pinyin-mspy"
           #:keymap 'mspy
           #:legends '(abc mspy)
           #:keyboards
           (list
            (keyboard "double-pinyin-mspy" 'standard-26 "double_pinyin_mspy" 'double-pinyin-center
                      #:rime-source-id "double_pinyin_mspy"
                      #:rime-deps '("stroke"))))
   (method "double-pinyin-pyjj"
           #:schema "double-pinyin-pyjj"
           #:keymap 'pyjj
           #:legends '(abc pyjj)
           #:keyboards
           (list
            (keyboard "double-pinyin-pyjj" 'standard-26 "double_pinyin_pyjj" 'double-pinyin-center
                      #:rime-source-id "double_pinyin_pyjj"
                      #:rime-deps '("stroke"))))
   (method "double-pinyin-st"
           #:schema "double-pinyin-st"
           #:keymap 'st
           #:legends '(abc st)
           #:keyboards
           (list
            (keyboard "double-pinyin-st" 'standard-26 "double_pinyin_st" 'double-pinyin-center
                      #:rime-source-id "double_pinyin_st"
                      #:rime-deps '("stroke"))))
   (method "wubi86"
           #:keymap 'wubi
           #:legends '(abc wubi)
           #:keyboards
           (list
            (keyboard "wubi86" 'standard-26 "wubi86" 'standard-top-center
                      #:rime-deps '("pinyin-simp")
                      #:rime-extra-files '("wubi86.dict.yaml"))
            (keyboard "wubi-pinyin" 'standard-26 "wubi86" 'standard-top-center
                      #:rime-source-id "wubi_pinyin"
                      #:rime-deps '("pinyin-simp")
                      #:rime-extra-files '("wubi86.dict.yaml"))
            (keyboard "wubi-trad" 'standard-26 "wubi86" 'standard-top-center
                      #:rime-source-id "wubi_trad"
                      #:rime-deps '("pinyin-simp")
                      #:rime-extra-files '("wubi86.dict.yaml"))))
   (method "stroke"
           #:keymap 'stroke
           #:legends '(abc stroke)
           #:keyboards
           (list
            (keyboard "stroke" 'standard-26 "stroke" 'standard-top-center
                      #:rime-deps '("luna-pinyin")
                      #:rime-extra-files '("stroke.dict.yaml"))))
   (method "pinyin-simp"
           #:schema "luna-pinyin"
           #:keymap 'abc
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "pinyin-simp" 'standard-26 "luna_pinyin" 'standard-center
                      #:rime-source-id "pinyin_simp"
                      #:rime-deps '("stroke")
                      #:rime-extra-files '("pinyin_simp.dict.yaml"))))))

(define input-method-keyboards
  (append-map input-method-dimension-keyboards input-method-dimensions))

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

(define input-method-recipe-by-id
  (for/hash ([recipe (in-list input-method-recipes)])
    (values (input-method-recipe-id recipe) recipe)))

(define (input-method-recipe-ref id [default #f])
  (hash-ref input-method-recipe-by-id id default))

(define (input-method-recipe-layouts id)
  (define recipe (input-method-recipe-ref id #f))
  (if recipe
      (input-method-recipe-keyboard-layouts recipe)
      '()))
