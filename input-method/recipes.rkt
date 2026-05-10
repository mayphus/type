#lang racket/base

(provide (struct-out input-method-recipe)
         input-method-recipes
         input-method-recipe-ref
         input-method-recipe-layouts)

(struct input-method-recipe
  (id
   schema
   skeleton
   projection
   legends
   placement
   interactions
   target
   keyboard-layouts)
  #:transparent)

(define (recipe id
                #:schema [schema id]
                #:skeleton skeleton
                #:projection projection
                #:legends [legends '()]
                #:placement placement
                #:interactions [interactions '(standard-mobile no-swipe-down)]
                #:target [target 'yuanshu]
                #:keyboard-layouts [keyboard-layouts (list id)])
  (input-method-recipe id
                       schema
                       skeleton
                       projection
                       legends
                       placement
                       interactions
                       target
                       keyboard-layouts))

(define input-method-recipes
  (list
   (recipe "flypy" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc flypy) #:placement 'split-flypy
           #:keyboard-layouts '("flypy"))
   (recipe "flypy_ice" #:schema "flypy" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc flypy) #:placement 'split-flypy
           #:keyboard-layouts '("flypy"))
   (recipe "flypy_14" #:skeleton 'compact-14 #:projection 'adjacent-qwerty-14
           #:legends '(flypy) #:placement 'compact-center
           #:interactions '(compact-mobile no-swipe-down)
           #:keyboard-layouts '("flypy_14"))
   (recipe "flypy_18" #:skeleton 'compact-18 #:projection 'adjacent-qwerty-18
           #:legends '(flypy) #:placement 'compact-center
           #:interactions '(compact-mobile no-swipe-down)
           #:keyboard-layouts '("flypy_18"))
   (recipe "shuffle_17" #:skeleton 'compact-17 #:projection 'shuffle-17
           #:legends '(flypy) #:placement 'compact-center
           #:interactions '(custom-mobile-pages no-swipe-down)
           #:keyboard-layouts '("shuffle_17"))
   (recipe "luna_pinyin" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc) #:placement 'standard-center
           #:keyboard-layouts '("luna_pinyin"))
   (recipe "terra_pinyin" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc) #:placement 'standard-center
           #:keyboard-layouts '("terra_pinyin"))
   (recipe "pinyin_14" #:skeleton 'compact-14 #:projection 'adjacent-qwerty-14
           #:legends '(abc) #:placement 'compact-center
           #:interactions '(compact-mobile no-swipe-down)
           #:keyboard-layouts '("pinyin_14"))
   (recipe "cangjie6" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(cangjie) #:placement 'standard-center
           #:keyboard-layouts '("cangjie6"))
   (recipe "jyut6ping3" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc jyutping) #:placement 'standard-top-center
           #:keyboard-layouts '("jyut6ping3"))
   (recipe "bopomofo" #:skeleton 'zhuyin #:projection 'zhuyin-direct
           #:legends '(zhuyin) #:placement 'standard-center
           #:interactions '(zhuyin-mobile custom-mobile-pages no-swipe-down)
           #:keyboard-layouts '("bopomofo"))
   (recipe "double_pinyin" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc zrm) #:placement 'double-pinyin-center
           #:keyboard-layouts '("double_pinyin_zrm"))
   (recipe "double_pinyin_abc" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc abc-dp) #:placement 'double-pinyin-center
           #:keyboard-layouts '("double_pinyin_abc"))
   (recipe "double_pinyin_flypy" #:schema "flypy" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc flypy) #:placement 'split-flypy
           #:keyboard-layouts '("flypy"))
   (recipe "double_pinyin_mspy" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc mspy) #:placement 'double-pinyin-center
           #:keyboard-layouts '("double_pinyin_mspy"))
   (recipe "double_pinyin_pyjj" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc pyjj) #:placement 'double-pinyin-center
           #:keyboard-layouts '("double_pinyin_pyjj"))
   (recipe "double_pinyin_st" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc st) #:placement 'double-pinyin-center
           #:keyboard-layouts '("double_pinyin_st"))
   (recipe "cangjie5" #:schema "cangjie6" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(cangjie) #:placement 'standard-center
           #:keyboard-layouts '("cangjie6"))
   (recipe "cangjie5_express" #:schema "cangjie6" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(cangjie) #:placement 'standard-center
           #:keyboard-layouts '("cangjie6"))
   (recipe "quick5" #:schema "cangjie6" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(cangjie) #:placement 'standard-center
           #:keyboard-layouts '("cangjie6"))
   (recipe "wubi86" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc wubi) #:placement 'standard-top-center
           #:keyboard-layouts '("wubi86"))
   (recipe "wubi_pinyin" #:schema "wubi86" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc wubi) #:placement 'standard-top-center
           #:keyboard-layouts '("wubi86"))
   (recipe "wubi_trad" #:schema "wubi86" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc wubi) #:placement 'standard-top-center
           #:keyboard-layouts '("wubi86"))
   (recipe "stroke" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc stroke) #:placement 'standard-top-center
           #:keyboard-layouts '("stroke"))
   (recipe "pinyin_simp" #:schema "luna_pinyin" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc) #:placement 'standard-center
           #:keyboard-layouts '("luna_pinyin"))
   (recipe "luna_quanpin" #:schema "luna_pinyin" #:skeleton 'standard-26 #:projection 'identity-26
           #:legends '(abc) #:placement 'standard-center
           #:keyboard-layouts '("luna_pinyin"))))

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
