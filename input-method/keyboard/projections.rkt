#lang racket/base

(provide keyboard-projection-definitions
         keyboard-projection-definition-ref)

(define keyboard-projection-definitions
  '((identity-26
     (summary "One schema key maps to one standard QWERTY slot.")
     (skeleton standard-26)
     (groups
      (q q) (w w) (e e) (r r) (t t) (y y) (u u) (i i) (o o) (p p)
      (a a) (s s) (d d) (f f) (g g) (h h) (j j) (k k) (l l)
      (z z) (x x) (c c) (v v) (b b) (n n) (m m)))
    (adjacent-qwerty-14
     (summary "Adjacent QWERTY pairs merge into the compact 14-key phone skeleton.")
     (skeleton compact-14)
     (groups
      (qw q w) (er e r) (ty t y) (ui u i) (op o p)
      (as a s) (df d f) (gh g h) (jk j k) (l l)
      (zx z x) (cv c v) (bn b n) (m m)))
    (adjacent-qwerty-18
     (summary "Screenshot-derived QWERTY groups merge into the compact 18-key phone skeleton.")
     (skeleton compact-18)
     (groups
      (q q) (we w e) (rt r t) (y y) (u u) (io i o) (p p)
      (a a) (sd s d) (fg f g) (h h) (jk j k) (l l)
      (z z) (xc x c) (v v) (bn b n) (m m)))
    (shuffle-17
     (summary "A shuffled 17-slot mobile projection using internal a-q codes.")
     (skeleton compact-17))
    (zhuyin-direct
     (summary "Bopomofo symbols map directly to the zhuyin skeleton.")
     (skeleton zhuyin))))

(define (keyboard-projection-definition-ref projection [default #f])
  (define projection-symbol
    (cond
      [(symbol? projection) projection]
      [(string? projection) (string->symbol projection)]
      [else projection]))
  (define entry
    (for/first ([definition (in-list keyboard-projection-definitions)]
                #:when (eq? (car definition) projection-symbol))
      (cdr definition)))
  (or entry default))
