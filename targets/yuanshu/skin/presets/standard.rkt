#lang racket/base

(require "../core/dsl.rkt"
         "../layouts/standard-numeric-page.rkt"
         "../layouts/standard-symbolic-page.rkt"
         "../layouts/standard-ipad-numeric-files.rkt")

(provide standard-config-data
         standard-secondary-files
         make-standard-keyboard-layout-files
         make-standard-skin-files)

(define pinyin-portrait-file-name "pinyinPortrait")
(define pinyin-landscape-file-name "pinyinLandscape")
(define numeric-portrait-file-name "numericPortrait")
(define numeric-landscape-file-name "numericLandscape")
(define symbolic-portrait-file-name "symbolicPortrait")
(define symbolic-landscape-file-name "symbolicLandscape")
(define ipad-pinyin-portrait-file-name "iPadPinyinPortrait")
(define ipad-pinyin-landscape-file-name "iPadPinyinLandscape")
(define ipad-numeric-portrait-file-name "iPadNumericPortrait")
(define ipad-numeric-landscape-file-name "iPadNumericLandscape")

(define standard-config-data
  (object
   ["numeric"
    (object
     ["iPad"
      (object
       ["floating" numeric-portrait-file-name]
       ["landscape" ipad-numeric-landscape-file-name]
       ["portrait" ipad-numeric-portrait-file-name])]
     ["iPhone"
      (object
       ["landscape" numeric-landscape-file-name]
       ["portrait" numeric-portrait-file-name])])]
   ["pinyin"
    (object
     ["iPad"
      (object
       ["floating" pinyin-portrait-file-name]
       ["landscape" ipad-pinyin-landscape-file-name]
       ["portrait" ipad-pinyin-portrait-file-name])]
     ["iPhone"
      (object
       ["landscape" pinyin-landscape-file-name]
       ["portrait" pinyin-portrait-file-name])])]
   ["symbolic"
    (object
     ["iPad"
      (object
       ["floating" symbolic-portrait-file-name]
       ["landscape" ipad-pinyin-landscape-file-name]
       ["portrait" ipad-pinyin-portrait-file-name])]
     ["iPhone"
      (object
       ["landscape" symbolic-landscape-file-name]
       ["portrait" symbolic-portrait-file-name])])]))

(define standard-secondary-files
  (bundle
   numeric-files
   symbolic-files
   standard-ipad-numeric-files))

(define (make-standard-keyboard-layout-files . page-groups)
  (apply bundle
         (append page-groups
                 (list standard-secondary-files
                       (json-file "config.yaml" standard-config-data)))))

(define make-standard-skin-files make-standard-keyboard-layout-files)
