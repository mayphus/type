#lang racket/base

(require "dsl.rkt")

(provide square-key-corner-radius
         square-key-size
         key-note-position)

(define square-key-corner-radius 6)

(define (square-key-size width [height width])
  (object ["width" width]
          ["height" height]))

(define (position x y)
  (object ["x" (json-number x)]
          ["y" (json-number y)]))

(define key-note-positions
  (hash 'center       (position "0.5" "0.5")
        'middle       (position "0.5" "0.5")
        'top          (position "0.5" "0.24")
        'bottom       (position "0.5" "0.76")
        'left         (position "0.24" "0.5")
        'right        (position "0.76" "0.5")
        'top-left     (position "0.24" "0.24")
        'top-right    (position "0.76" "0.24")
        'bottom-left  (position "0.24" "0.76")
        'bottom-right (position "0.76" "0.76")))

(define (key-note-position name)
  (hash-ref key-note-positions
            name
            (lambda ()
              (error 'key-note-position "unknown key note position: ~a" name))))
