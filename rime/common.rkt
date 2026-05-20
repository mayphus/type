#lang racket/base

(require "../dsl/yaml.rkt")

(provide common-schema-processors
         common-schema-segmentors
         common-schema-filters)

(define common-schema-processors
  (sequence
   "ascii_composer"
   "recognizer"
   "key_binder"
   "speller"
   "punctuator"
   "selector"
   "navigator"
   "express_editor"))

(define common-schema-segmentors
  (sequence
   "ascii_segmentor"
   "matcher"
   "abc_segmentor"
   "punct_segmentor"
   "fallback_segmentor"))

(define common-schema-filters
  (sequence
   "simplifier"
   "uniquifier"))
