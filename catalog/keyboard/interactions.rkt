#lang racket/base

(require "../../lang/keyboard.rkt")

(provide keyboard-interaction-definitions
         keyboard-interaction-definition-ref)

(define-catalog keyboard-interaction-definitions
  (standard-mobile
   (summary "Default Yuanshu alphabetic keys with swipe-up symbol entry."))
  (no-swipe-down
   (summary "Generated layouts intentionally avoid swipe-down actions."))
  (compact-mobile
   (summary "Compact merged-key phone layouts with standard system last row."))
  (custom-mobile-pages
   (summary "Layout owns custom phone or iPad pages beyond the standard renderer."))
  (zhuyin-mobile
   (summary "Bopomofo mobile page with custom candidate, preedit, and toolbar chrome."))
  (standard-desktop
   (summary "Desktop-oriented physical keyboard without mobile gesture behavior.")))

(define (keyboard-interaction-definition-ref interaction (default #f))
  (catalog-definition-ref keyboard-interaction-definitions interaction default))
