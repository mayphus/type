#lang racket/base

(require racket/hash
         "dsl.rkt"
         "../layouts/base-page.rkt")

(provide make-pinyin-bundle
         make-grid-page)

;; Generate the standard 4-way pinyin skin bundle (Light/Dark x Portrait/Landscape)
(define (make-pinyin-bundle portrait-name landscape-name page-builder)
  (bundle
   (json-file (yaml-page "light" portrait-name)  (page-builder #f #t))
   (json-file (yaml-page "dark"  portrait-name)  (page-builder #t #t))
   (json-file (yaml-page "light" landscape-name) (page-builder #f #f))
   (json-file (yaml-page "dark"  landscape-name) (page-builder #t #f))))

;; Generic builder for a grid-based keyboard page
(define (make-grid-page dark? portrait? 
                        #:base-page-builder base-page-builder
                        #:keyboard-layout keyboard-layout
                        #:button-specs button-specs
                        #:button-renderer button-renderer
                        #:extra-entries [extra-entries (hash)])
  (define button-hash
    (for/fold ([acc (hash)]) ([spec (in-list button-specs)])
      (for/fold ([inner acc]) ([entry (in-list (button-renderer dark? spec))])
        (hash-set inner (car entry) (cdr entry)))))
  
  (define combined
    (hash-union (base-page-builder dark? portrait?)
                (hash-set button-hash "keyboardLayout" keyboard-layout)
                extra-entries
                #:combine/key (lambda (_ left _right) left)))
  
  (auto-ordered-page combined))
