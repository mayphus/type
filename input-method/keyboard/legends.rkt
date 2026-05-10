#lang racket/base

(provide keyboard-legend-definitions
         keyboard-legend-definition-ref
         keyboard-legend-text)

(define (legend-entry key text)
  (cons key text))

(define (legend-layer layer . entries)
  (cons layer (make-immutable-hash entries)))

(define (keyboard-legends . layers)
  (make-immutable-hash layers))

(define keyboard-legend-definitions
  (keyboard-legends
   (legend-layer 'wubi
    (legend-entry 'q "金/勹") (legend-entry 'w "人/八") (legend-entry 'e "月/彡") (legend-entry 'r "白/手") (legend-entry 't "禾/竹")
    (legend-entry 'y "言/文") (legend-entry 'u "立/辛") (legend-entry 'i "水/小") (legend-entry 'o "火/米") (legend-entry 'p "之/宀")
    (legend-entry 'a "工/戈") (legend-entry 's "木/丁") (legend-entry 'd "大/犬") (legend-entry 'f "土/十") (legend-entry 'g "王/一")
    (legend-entry 'h "目/止") (legend-entry 'j "日/虫") (legend-entry 'k "口/川") (legend-entry 'l "田/力")
    (legend-entry 'z "拼音") (legend-entry 'x "纟/弓") (legend-entry 'c "又/巴") (legend-entry 'v "女/刀") (legend-entry 'b "子/耳")
    (legend-entry 'n "已/心") (legend-entry 'm "山/贝"))
   (legend-layer 'stroke
    (legend-entry 'h "一") (legend-entry 's "丨") (legend-entry 'p "丿") (legend-entry 'n "丶") (legend-entry 'z "乙")
    (legend-entry 'j "一") (legend-entry 'k "丨") (legend-entry 'l "丿") (legend-entry 'u "丶") (legend-entry 'i "乙"))
   (legend-layer 'zrm
    (legend-entry 'q "iu") (legend-entry 'w "ia/ua") (legend-entry 'e "e") (legend-entry 'r "uan") (legend-entry 't "ue/ve")
    (legend-entry 'y "ing/uai") (legend-entry 'u "sh") (legend-entry 'i "ch") (legend-entry 'o "uo") (legend-entry 'p "un")
    (legend-entry 'a "a") (legend-entry 's "ong") (legend-entry 'd "uang") (legend-entry 'f "en") (legend-entry 'g "eng")
    (legend-entry 'h "ang") (legend-entry 'j "an") (legend-entry 'k "ao") (legend-entry 'l "ai")
    (legend-entry 'z "ei") (legend-entry 'x "ie") (legend-entry 'c "iao") (legend-entry 'v "zh/ui") (legend-entry 'b "ou")
    (legend-entry 'n "in") (legend-entry 'm "ian"))
   (legend-layer 'abc-dp
    (legend-entry 'q "ei") (legend-entry 'w "ian") (legend-entry 'e "ch") (legend-entry 'r "er/iu") (legend-entry 't "iang")
    (legend-entry 'y "ing") (legend-entry 'u "u") (legend-entry 'i "i") (legend-entry 'o "uo/零") (legend-entry 'p "uan")
    (legend-entry 'a "zh") (legend-entry 's "ong") (legend-entry 'd "ia/ua") (legend-entry 'f "en") (legend-entry 'g "eng")
    (legend-entry 'h "ang") (legend-entry 'j "an") (legend-entry 'k "ao") (legend-entry 'l "ai")
    (legend-entry 'z "iao") (legend-entry 'x "ie") (legend-entry 'c "in/uai") (legend-entry 'v "sh") (legend-entry 'b "ou")
    (legend-entry 'n "un") (legend-entry 'm "ui/ue"))
   (legend-layer 'mspy
    (legend-entry 'q "iu") (legend-entry 'w "ia/ua") (legend-entry 'e "e") (legend-entry 'r "er/uan") (legend-entry 't "ue/ve")
    (legend-entry 'y "v/uai") (legend-entry 'u "sh") (legend-entry 'i "ch") (legend-entry 'o "uo") (legend-entry 'p "un")
    (legend-entry 'a "a") (legend-entry 's "ong") (legend-entry 'd "uang") (legend-entry 'f "en") (legend-entry 'g "eng")
    (legend-entry 'h "ang") (legend-entry 'j "an") (legend-entry 'k "ao") (legend-entry 'l "ai")
    (legend-entry 'z "ei") (legend-entry 'x "ie") (legend-entry 'c "iao") (legend-entry 'v "zh/ui") (legend-entry 'b "ou")
    (legend-entry 'n "in") (legend-entry 'm "ian"))
   (legend-layer 'pyjj
    (legend-entry 'q "er/ing") (legend-entry 'w "ei") (legend-entry 'e "e") (legend-entry 'r "en") (legend-entry 't "eng")
    (legend-entry 'y "ong") (legend-entry 'u "ch") (legend-entry 'i "sh") (legend-entry 'o "uo") (legend-entry 'p "ou")
    (legend-entry 'a "a") (legend-entry 's "ai") (legend-entry 'd "ao") (legend-entry 'f "an") (legend-entry 'g "ang")
    (legend-entry 'h "uang") (legend-entry 'j "ian") (legend-entry 'k "iao") (legend-entry 'l "in")
    (legend-entry 'z "un") (legend-entry 'x "ve/uai") (legend-entry 'c "uan") (legend-entry 'v "zh/ui") (legend-entry 'b "ia/ua")
    (legend-entry 'n "iu") (legend-entry 'm "ie"))
   (legend-layer 'st
    (legend-entry 'q "er") (legend-entry 'w "ei") (legend-entry 'e "e") (legend-entry 'r "en") (legend-entry 't "eng")
    (legend-entry 'y "ong") (legend-entry 'u "ch") (legend-entry 'i "sh") (legend-entry 'o "uo") (legend-entry 'p "ou")
    (legend-entry 'a "zh") (legend-entry 's "ai") (legend-entry 'd "ao") (legend-entry 'f "an") (legend-entry 'g "ang")
    (legend-entry 'h "uang") (legend-entry 'j "ian") (legend-entry 'k "iao") (legend-entry 'l "in")
    (legend-entry 'z "un") (legend-entry 'x "v/uai") (legend-entry 'c "uan") (legend-entry 'v "ui/ue") (legend-entry 'b "ia/ua")
    (legend-entry 'n "iu") (legend-entry 'm "ie"))
   (legend-layer 'jyutping
    (legend-entry 'q "—") (legend-entry 'w "w") (legend-entry 'e "e/eo") (legend-entry 'r "—") (legend-entry 't "t") (legend-entry 'y "yu")
    (legend-entry 'u "u/yun") (legend-entry 'i "i") (legend-entry 'o "o/oe") (legend-entry 'p "p")
    (legend-entry 'a "aa/a") (legend-entry 's "s") (legend-entry 'd "d") (legend-entry 'f "f") (legend-entry 'g "g/gw")
    (legend-entry 'h "h") (legend-entry 'j "j") (legend-entry 'k "k/kw") (legend-entry 'l "l")
    (legend-entry 'z "z") (legend-entry 'x "—") (legend-entry 'c "c") (legend-entry 'v "—") (legend-entry 'b "b")
    (legend-entry 'n "n/ng") (legend-entry 'm "m/ng"))))

(define (keyboard-legend-definition-ref layer [default #f])
  (define layer-symbol
    (cond
      [(symbol? layer) layer]
      [(string? layer) (string->symbol layer)]
      [else layer]))
  (hash-ref keyboard-legend-definitions layer-symbol (lambda () default)))

(define (keyboard-legend-text layer key [default ""])
  (define table (keyboard-legend-definition-ref layer))
  (if table
      (hash-ref table key (lambda () default))
      default))
