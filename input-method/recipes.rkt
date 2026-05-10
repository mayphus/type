#lang racket/base

(require racket/list)

(provide (struct-out input-method-recipe)
         (struct-out keyboard-dimension)
         (struct-out input-method-dimension)
         input-method-keyboards
         keyboard-dimensions
         input-method-dimensions
         calculate-input-method-recipes
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

(struct keyboard-dimension
  (id
   skeleton
   projection
   interactions
   target)
  #:transparent)

(struct input-method-keyboard
  (recipe-id
   keyboard-id
   layout-id
   placement)
  #:transparent)

(struct input-method-dimension
  (id
   schema
   legends
   keyboards)
  #:transparent)

(define keyboard-dimensions
  (list
   (keyboard-dimension 'standard-26
                       'standard-26
                       'identity-26
                       '(standard-mobile no-swipe-down)
                       'yuanshu)
   (keyboard-dimension 'compact-14
                       'compact-14
                       'adjacent-qwerty-14
                       '(compact-mobile no-swipe-down)
                       'yuanshu)
   (keyboard-dimension 'compact-18
                       'compact-18
                       'adjacent-qwerty-18
                       '(compact-mobile no-swipe-down)
                       'yuanshu)
   (keyboard-dimension 'shuffle-17
                       'compact-17
                       'shuffle-17
                       '(custom-mobile-pages no-swipe-down)
                       'yuanshu)
   (keyboard-dimension 'zhuyin
                       'zhuyin
                       'zhuyin-direct
                       '(zhuyin-mobile custom-mobile-pages no-swipe-down)
                       'yuanshu)))

(define keyboard-dimension-by-id
  (for/hash ([dimension (in-list keyboard-dimensions)])
    (values (keyboard-dimension-id dimension) dimension)))

(define (keyboard-dimension-ref id)
  (hash-ref keyboard-dimension-by-id
            id
            (lambda ()
              (error 'keyboard-dimension-ref "unknown keyboard dimension: ~a" id))))

(define (keyboard recipe-id keyboard-id layout-id placement)
  (input-method-keyboard recipe-id keyboard-id layout-id placement))

(define (method id
                #:schema [schema id]
                #:legends [legends '()]
                #:keyboards keyboards)
  (input-method-dimension id schema legends keyboards))

(define input-method-dimensions
  (list
   (method "flypy"
           #:legends '(abc flypy)
           #:keyboards
           (list
            (keyboard "flypy" 'standard-26 "flypy" 'split-flypy)
            (keyboard "flypy_14" 'compact-14 "flypy_14" 'compact-center)
            (keyboard "flypy_18" 'compact-18 "flypy_18" 'compact-center)
            (keyboard "shuffle_17" 'shuffle-17 "shuffle_17" 'compact-center)))
   (method "luna_pinyin"
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "luna_pinyin" 'standard-26 "luna_pinyin" 'standard-center)
            (keyboard "pinyin_14" 'compact-14 "pinyin_14" 'compact-center)))
   (method "terra_pinyin"
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "terra_pinyin" 'standard-26 "terra_pinyin" 'standard-center)))
   (method "cangjie6"
           #:legends '(cangjie)
           #:keyboards
           (list
            (keyboard "cangjie6" 'standard-26 "cangjie6" 'standard-center)
            (keyboard "cangjie5" 'standard-26 "cangjie6" 'standard-center)
            (keyboard "cangjie5_express" 'standard-26 "cangjie6" 'standard-center)
            (keyboard "quick5" 'standard-26 "cangjie6" 'standard-center)))
   (method "jyut6ping3"
           #:legends '(abc jyutping)
           #:keyboards
           (list
            (keyboard "jyut6ping3" 'standard-26 "jyut6ping3" 'standard-top-center)))
   (method "bopomofo"
           #:legends '(zhuyin)
           #:keyboards
           (list
            (keyboard "bopomofo" 'zhuyin "bopomofo" 'standard-center)))
   (method "double_pinyin"
           #:legends '(abc zrm)
           #:keyboards
           (list
            (keyboard "double_pinyin" 'standard-26 "double_pinyin_zrm" 'double-pinyin-center)))
   (method "double_pinyin_abc"
           #:legends '(abc abc-dp)
           #:keyboards
           (list
            (keyboard "double_pinyin_abc" 'standard-26 "double_pinyin_abc" 'double-pinyin-center)))
   (method "double_pinyin_flypy"
           #:schema "flypy"
           #:legends '(abc flypy)
           #:keyboards
           (list
            (keyboard "double_pinyin_flypy" 'standard-26 "flypy" 'split-flypy)))
   (method "double_pinyin_mspy"
           #:legends '(abc mspy)
           #:keyboards
           (list
            (keyboard "double_pinyin_mspy" 'standard-26 "double_pinyin_mspy" 'double-pinyin-center)))
   (method "double_pinyin_pyjj"
           #:legends '(abc pyjj)
           #:keyboards
           (list
            (keyboard "double_pinyin_pyjj" 'standard-26 "double_pinyin_pyjj" 'double-pinyin-center)))
   (method "double_pinyin_st"
           #:legends '(abc st)
           #:keyboards
           (list
            (keyboard "double_pinyin_st" 'standard-26 "double_pinyin_st" 'double-pinyin-center)))
   (method "wubi86"
           #:legends '(abc wubi)
           #:keyboards
           (list
            (keyboard "wubi86" 'standard-26 "wubi86" 'standard-top-center)
            (keyboard "wubi_pinyin" 'standard-26 "wubi86" 'standard-top-center)
            (keyboard "wubi_trad" 'standard-26 "wubi86" 'standard-top-center)))
   (method "stroke"
           #:legends '(abc stroke)
           #:keyboards
           (list
            (keyboard "stroke" 'standard-26 "stroke" 'standard-top-center)))
   (method "pinyin_simp"
           #:schema "luna_pinyin"
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "pinyin_simp" 'standard-26 "luna_pinyin" 'standard-center)))
   (method "luna_quanpin"
           #:schema "luna_pinyin"
           #:legends '(abc)
           #:keyboards
           (list
            (keyboard "luna_quanpin" 'standard-26 "luna_pinyin" 'standard-center)))))

(define input-method-keyboards
  (append-map input-method-dimension-keyboards input-method-dimensions))

(define (input-method-keyboard->recipe method-dimension method-keyboard)
  (define keyboard-dimension
    (keyboard-dimension-ref (input-method-keyboard-keyboard-id method-keyboard)))
  (input-method-recipe
   (input-method-keyboard-recipe-id method-keyboard)
   (input-method-dimension-schema method-dimension)
   (keyboard-dimension-skeleton keyboard-dimension)
   (keyboard-dimension-projection keyboard-dimension)
   (input-method-dimension-legends method-dimension)
   (input-method-keyboard-placement method-keyboard)
   (keyboard-dimension-interactions keyboard-dimension)
   (keyboard-dimension-target keyboard-dimension)
   (list (input-method-keyboard-layout-id method-keyboard))))

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
