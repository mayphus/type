#lang racket/base

(require "../core/dsl.rkt"
         "../core/visual-policy.rkt"
         "../keysets/pinyin-common.rkt"
         "flypy18-page.rkt"
         "compact-14-page.rkt")

(provide pinyin-14-iphone-pinyin-files)

(define button-specs
  (list
   (merged18-spec "qw14Button" "q" "QW" "" compact-14-key-size #f #f)
   (merged18-spec "er14Button" "e" "ER" "" compact-14-key-size #f #f)
   (merged18-spec "ty14Button" "t" "TY" "" compact-14-key-size #f #f)
   (merged18-spec "ui14Button" "u" "UI" "" compact-14-key-size #f #f)
   (merged18-spec "op14Button" "o" "OP" "" compact-14-key-size #f #f)
   (merged18-spec "as14Button" "a" "AS" "" compact-14-key-size #f #f)
   (merged18-spec "df14Button" "d" "DF" "" compact-14-key-size #f #f)
   (merged18-spec "gh14Button" "g" "GH" "" compact-14-key-size #f #f)
   (merged18-spec "jk14Button" "j" "JK" "" compact-14-key-size #f #f)
   (merged18-spec "l14Button" "l" "L" "" compact-14-key-size #f #f)
   (merged18-spec "zx14Button" "z" "ZX" "" compact-14-key-size #f #f)
   (merged18-spec "cv14Button" "c" "CV" "" compact-14-key-size #f #f)
   (merged18-spec "bn14Button" "b" "BN" "" compact-14-key-size #f #f)
   (merged18-spec "m14Button" "m" "M" "" compact-14-key-size #f #f)))

(define centered-label-center
  (object ["x" (json-number "0.5")]
          ["y" (json-number "0.5")]))

(define pinyin-14-iphone-pinyin-files
  (make-compact-14-files
   #:button-specs button-specs
   #:detail-font-size 10
   #:label-center centered-label-center))
