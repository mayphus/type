#lang racket/base

(require racket/list
         "keyboard.rkt"
         "../lang/type.rkt"
         "../type.rkt")

(provide (all-from-out "../lang/type.rkt")
         input-methods
         (struct-out input-method-recipe)
         input-method-keyboards
         input-method-methods
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
         rime-schema-artifacts)

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

(define rime-entries input-method-recipes)

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
