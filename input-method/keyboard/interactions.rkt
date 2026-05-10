#lang racket/base

(provide keyboard-interaction-definitions
         keyboard-interaction-definition-ref)

(define keyboard-interaction-definitions
  '((standard-mobile
     (summary "Default Yuanshu alphabetic keys with swipe-up symbol entry."))
    (no-swipe-down
     (summary "Generated layouts intentionally avoid swipe-down actions."))
    (compact-mobile
     (summary "Compact merged-key phone layouts with standard system last row."))
    (custom-mobile-pages
     (summary "Layout owns custom phone or iPad pages beyond the standard renderer."))
    (zhuyin-mobile
     (summary "Bopomofo mobile page with custom candidate, preedit, and toolbar chrome."))))

(define (keyboard-interaction-definition-ref interaction [default #f])
  (define interaction-symbol
    (cond
      [(symbol? interaction) interaction]
      [(string? interaction) (string->symbol interaction)]
      [else interaction]))
  (define entry
    (for/first ([definition (in-list keyboard-interaction-definitions)]
                #:when (eq? (car definition) interaction-symbol))
      (cdr definition)))
  (or entry default))
