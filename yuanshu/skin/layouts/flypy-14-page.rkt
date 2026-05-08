#lang racket/base

(require "../core/visual-policy.rkt"
         "../keysets/pinyin-common.rkt"
         "flypy18-page.rkt"
         "compact-14-page.rkt")

(provide flypy-14-iphone-pinyin-files)

(define button-specs
  (list
   (merged18-spec "qw14Button" "q" "QW" "iu ei ia ua" compact-14-key-size #f #f)
   (merged18-spec "er14Button" "e" "ER" "e uan" compact-14-key-size #f (key-spec-swipe-down (find-hybrid-letter-spec "e")))
   (merged18-spec "ty14Button" "t" "TY" "ue un ing uai" compact-14-key-size #f #f)
   (merged18-spec "ui14Button" "u" "UI" "sh ch u" compact-14-key-size #f #f)
   (merged18-spec "op14Button" "o" "OP" "uo ie" compact-14-key-size #f #f)
   (merged18-spec "as14Button" "a" "AS" "a ong" compact-14-key-size #f #f)
   (merged18-spec "df14Button" "d" "DF" "ai en" compact-14-key-size #f #f)
   (merged18-spec "gh14Button" "g" "GH" "eng ang" compact-14-key-size #f #f)
   (merged18-spec "jk14Button" "j" "JK" "an ing" compact-14-key-size #f #f)
   (merged18-spec "l14Button" "l" "L" "iang uang" compact-14-key-size #f #f)
   (merged18-spec "zx14Button" "z" "ZX" "ou ia" compact-14-key-size #f #f)
   (merged18-spec "cv14Button" "c" "CV" "ao zh ui" compact-14-key-size #f #f)
   (merged18-spec "bn14Button" "b" "BN" "in iao" compact-14-key-size #f #f)
   (merged18-spec "m14Button" "m" "M" "ian" compact-14-key-size #f #f)))

(define flypy-14-iphone-pinyin-files
  (make-compact-14-files
   #:button-specs button-specs
   #:detail-font-size 7.5))
