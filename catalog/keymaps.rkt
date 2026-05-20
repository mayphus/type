#lang racket/base

(provide keymap-definitions
         keymap-ref
         keymap-text
         keyboard-legend-definitions
         keyboard-legend-definition-ref
         keyboard-legend-text)

(define (legend-entry key text)
  (cons key text))

(define (legend-layer layer . entries)
  (cons layer (make-immutable-hash entries)))

(define (keyboard-legends . layers)
  (make-immutable-hash layers))

(define-syntax-rule (define-keymaps name (layer (key text) ...) ...)
  (define name
    (keyboard-legends
     (legend-layer 'layer
       (legend-entry 'key text) ...)
     ...)))

(define-keymaps keyboard-legend-definitions
  (abc
   (q "q") (w "w") (e "e") (r "r") (t "t") (y "y") (u "u") (i "i") (o "o") (p "p")
   (a "a") (s "s") (d "d") (f "f") (g "g") (h "h") (j "j") (k "k") (l "l")
   (z "z") (x "x") (c "c") (v "v") (b "b") (n "n") (m "m"))
  (flypy
   (q "iu") (w "ei") (e "e") (r "uan") (t "ue/ve") (y "un") (u "sh") (i "ch") (o "uo") (p "ie")
   (a "a") (s "ong/iong") (d "ai") (f "en") (g "eng") (h "ang") (j "an") (k "ing/uai") (l "iang/uang")
   (z "ou") (x "ia/ua") (c "ao") (v "zh/ui") (b "in") (n "iao") (m "ian"))
  (cangjie
   (q "手") (w "田") (e "水") (r "口") (t "廿") (y "卜") (u "山") (i "戈") (o "人") (p "心")
   (a "日") (s "尸") (d "木") (f "火") (g "土") (h "的") (j "十") (k "大") (l "中")
   (z "片") (x "止") (c "金") (v "女") (b "月") (n "弓") (m "一"))
  (zhuyin
   (bo "ㄅ") (po "ㄆ") (mo "ㄇ") (fo "ㄈ") (de "ㄉ") (te "ㄊ") (ne "ㄋ") (le "ㄌ") (ge "ㄍ") (ke "ㄎ") (he "ㄏ")
   (ji "ㄐ") (qi "ㄑ") (xi "ㄒ") (zhi "ㄓ") (chi "ㄔ") (shi "ㄕ") (ri "ㄖ") (zi "ㄗ") (ci "ㄘ") (si "ㄙ")
   (yi "ㄧ") (wu "ㄨ") (yu "ㄩ") (a "ㄚ") (o "ㄛ") (e "ㄜ") (eh "ㄝ") (ai "ㄞ") (ei "ㄟ") (ao "ㄠ") (ou "ㄡ")
   (an "ㄢ") (en "ㄣ") (ang "ㄤ") (eng "ㄥ") (er "ㄦ") (second-tone "ˊ") (third-tone "ˇ") (fourth-tone "ˋ") (light-tone "˙"))
  (zhuyin-standard
   (one "ㄅ") (q "ㄆ") (a "ㄇ") (z "ㄈ")
   (two "ㄉ") (w "ㄊ") (s "ㄋ") (x "ㄌ")
   (e "ㄍ") (d "ㄎ") (c "ㄏ")
   (r "ㄐ") (f "ㄑ") (v "ㄒ")
   (five "ㄓ") (t "ㄔ") (g "ㄕ") (b "ㄖ")
   (y "ㄗ") (h "ㄘ") (n "ㄙ")
   (u "ㄧ") (j "ㄨ") (m "ㄩ")
   (eight "ㄚ") (i "ㄛ") (k "ㄜ") (comma "ㄝ")
   (nine "ㄞ") (o "ㄟ") (l "ㄠ") (period "ㄡ")
   (zero "ㄢ") (p "ㄣ") (semicolon "ㄤ") (slash "ㄥ")
   (minus "ㄦ") (six "ˊ") (three "ˇ") (four "ˋ") (seven "˙"))
  (wubi
   (q "金/勹") (w "人/八") (e "月/彡") (r "白/手") (t "禾/竹") (y "言/文") (u "立/辛") (i "水/小") (o "火/米") (p "之/宀")
   (a "工/戈") (s "木/丁") (d "大/犬") (f "土/十") (g "王/一") (h "目/止") (j "日/虫") (k "口/川") (l "田/力")
   (z "拼音") (x "纟/弓") (c "又/巴") (v "女/刀") (b "子/耳") (n "已/心") (m "山/贝"))
  (stroke
   (h "一") (s "丨") (p "丿") (n "丶") (z "乙")
   (j "一") (k "丨") (l "丿") (u "丶") (i "乙"))
  (zrm
   (q "iu") (w "ia/ua") (e "e") (r "uan") (t "ue/ve") (y "ing/uai") (u "sh") (i "ch") (o "uo") (p "un")
   (a "a") (s "ong") (d "uang") (f "en") (g "eng") (h "ang") (j "an") (k "ao") (l "ai")
   (z "ei") (x "ie") (c "iao") (v "zh/ui") (b "ou") (n "in") (m "ian"))
  (abc-dp
   (q "ei") (w "ian") (e "ch") (r "er/iu") (t "iang") (y "ing") (u "u") (i "i") (o "uo/零") (p "uan")
   (a "zh") (s "ong") (d "ia/ua") (f "en") (g "eng") (h "ang") (j "an") (k "ao") (l "ai")
   (z "iao") (x "ie") (c "in/uai") (v "sh") (b "ou") (n "un") (m "ui/ue"))
  (mspy
   (q "iu") (w "ia/ua") (e "e") (r "er/uan") (t "ue/ve") (y "v/uai") (u "sh") (i "ch") (o "uo") (p "un")
   (a "a") (s "ong") (d "uang") (f "en") (g "eng") (h "ang") (j "an") (k "ao") (l "ai")
   (z "ei") (x "ie") (c "iao") (v "zh/ui") (b "ou") (n "in") (m "ian"))
  (pyjj
   (q "er/ing") (w "ei") (e "e") (r "en") (t "eng") (y "ong") (u "ch") (i "sh") (o "uo") (p "ou")
   (a "a") (s "ai") (d "ao") (f "an") (g "ang") (h "uang") (j "ian") (k "iao") (l "in")
   (z "un") (x "ve/uai") (c "uan") (v "zh/ui") (b "ia/ua") (n "iu") (m "ie"))
  (st
   (q "er") (w "ei") (e "e") (r "en") (t "eng") (y "ong") (u "ch") (i "sh") (o "uo") (p "ou")
   (a "zh") (s "ai") (d "ao") (f "an") (g "ang") (h "uang") (j "ian") (k "iao") (l "in")
   (z "un") (x "v/uai") (c "uan") (v "ui/ue") (b "ia/ua") (n "iu") (m "ie"))
  (jyutping
   (q "—") (w "w") (e "e/eo") (r "—") (t "t") (y "yu") (u "u/yun") (i "i") (o "o/oe") (p "p")
   (a "aa/a") (s "s") (d "d") (f "f") (g "g/gw") (h "h") (j "j") (k "k/kw") (l "l")
   (z "z") (x "—") (c "c") (v "—") (b "b") (n "n/ng") (m "m/ng")))

(define (keyboard-legend-definition-ref layer (default #f))
  (define layer-symbol
    (cond
      ((symbol? layer) layer)
      ((string? layer) (string->symbol layer))
      (else layer)))
  (hash-ref keyboard-legend-definitions layer-symbol (lambda () default)))

(define (keyboard-legend-text layer key (default ""))
  (define table (keyboard-legend-definition-ref layer))
  (if table
      (hash-ref table key (lambda () default))
      default))

(define keymap-definitions keyboard-legend-definitions)
(define keymap-ref keyboard-legend-definition-ref)
(define keymap-text keyboard-legend-text)
