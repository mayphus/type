#lang racket/base

(require "../keysets/pinyin-common.rkt"
         "flypy18-page.rkt"
         "compact-9-page.rkt")

(provide flypy-9-iphone-pinyin-files)

(define button-specs
  (list
   (merged18-spec "qwe9Button" "q" "QWE" "iu ei e" compact-9-key-size #f #f)
   (merged18-spec "rty9Button" "r" "RTY" "uan ue un" compact-9-key-size #f #f)
   (merged18-spec "uiop9Button" "u" "UIOP" "sh ch uo ie" compact-9-key-size #f #f)
   (merged18-spec "asd9Button" "a" "ASD" "a ong ai" compact-9-key-size #f #f)
   (merged18-spec "fgh9Button" "f" "FGH" "en eng ang" compact-9-key-size #f #f)
   (merged18-spec "jkl9Button" "j" "JKL" "an ing iang" compact-9-key-size #f #f)
   (merged18-spec "zxc9Button" "z" "ZXC" "ou ia ao" compact-9-key-size #f #f)
   (merged18-spec "vbn9Button" "v" "VBN" "zh ui in iao" compact-9-key-size #f #f)
   (merged18-spec "m9Button" "m" "M" "ian" compact-9-key-size #f #f)))

(define flypy-9-iphone-pinyin-files
  (make-compact-9-files
   #:button-specs button-specs
   #:detail-font-size 7.5))
