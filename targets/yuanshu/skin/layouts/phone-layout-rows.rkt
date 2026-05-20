#lang racket/base

(require "../core/dsl.rkt")

(provide keyboard-layout-row
         standard-pinyin-last-row)

(define (layout-cell id)
  (object ["Cell" id]))

(define (keyboard-layout-row ids)
  (object ["HStack"
           (object ["subviews"
                    (list->vector (map layout-cell ids))])]))

(define standard-pinyin-last-row
  (keyboard-layout-row
   '("numericButton"
     "emojiButton"
     "spaceButton"
     "semicolonButton"
     "enterButton")))
