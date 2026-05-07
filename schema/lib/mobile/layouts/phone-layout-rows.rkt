#lang racket/base

(require "../core/dsl.rkt")

(provide standard-pinyin-last-row)

(define (layout-cell id)
  (object ["Cell" id]))

(define standard-pinyin-last-row
  (object ["HStack"
           (object ["subviews"
                    (array (layout-cell "numericButton")
                           (layout-cell "emojiButton")
                           (layout-cell "spaceButton")
                           (layout-cell "semicolonButton")
                           (layout-cell "enterButton"))])]))
