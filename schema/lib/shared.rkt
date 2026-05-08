#lang racket/base

(require racket/format
         "../../lib/yaml/dsl.rkt")

(provide common-schema-processors
         common-schema-segmentors
         common-schema-filters
         yuanshu-common-patch
         yuanshu-script-patch
         yuanshu-reverse-lookup-patch
         make-shared-config-files
         make-mobile-custom-file)

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

(define yuanshu-common-patch
  (mapping
   (kv "punctuator"
       (mapping
        (kv "__include" "default:/punctuator")
        (kv "full_shape"
            (mapping
             (kv "__include" "default:/punctuator/full_shape")))
        (kv "half_shape"
            (mapping
             (kv "__include" "default:/punctuator/half_shape")))))
   (kv "recognizer"
       (mapping
        (kv "import_preset" "default")))
   (kv "key_binder"
       (mapping
        (kv "import_preset" "default")))
   (kv "editor"
       (mapping
        (kv "bindings"
            (mapping
             (kv "space" "confirm")
             (kv "Return" "commit_raw_input")
             (kv "BackSpace" "revert")
             (kv "Escape" "cancel")))))))

(define yuanshu-script-patch
  (mapping
   (kv "engine/translators"
       (sequence
        "punct_translator"
        "script_translator"))
   (kv "engine/filters"
       (sequence
        "simplifier"
        "uniquifier"))))

(define yuanshu-reverse-lookup-patch
  (mapping
   (kv "engine/translators"
       (sequence
        "punct_translator"
        "reverse_lookup_translator"
        "script_translator"))
   (kv "engine/filters"
       (sequence
        "simplifier"
        "uniquifier"))
   (kv "recognizer/patterns/reverse_lookup" "`[a-z]*'?$")))

(define (shared-include name)
  (mapping
   (kv "patch/+"
       (mapping
        (kv "__include" (format "yuanshu_shared:/~a" name))))))

(define (make-shared-config-files)
  (yaml-file
   "yuanshu_shared.yaml"
   (mapping
    (kv "yuanshu_common_patch" yuanshu-common-patch)
    (kv "yuanshu_script_patch" yuanshu-script-patch)
    (kv "yuanshu_reverse_lookup_patch" yuanshu-reverse-lookup-patch))))

(define (make-mobile-custom-file filename include-names patch)
  (yaml-file
   filename
   (mapping
    (kv "__patch"
        (apply sequence (map shared-include include-names)))
    (kv "patch" patch))))
