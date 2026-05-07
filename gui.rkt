#lang racket/base

(require racket/class
         racket/gui/base
         racket/list
         racket/string
         "build.rkt")

(provide start-gui)

(struct option (id name catalog) #:transparent)

(define app-profile-name "rime-config")
(define mobile-output-name "gui-mobile")
(define mobile-skins-output-name "gui-mobile-skins")
(define default-schema-ids '("flypy"))
(define gui-schema-ids
  (remove-duplicates (append generated-config-ids '("bopomofo"))))

(define schema-catalog-order
  '("double-pinyin" "full-pinyin" "shape" "cantonese" "phonetic" "other"))

(define (schema-catalog-id id)
  (cond
    [(member id '("flypy" "flypy_ice" "flypy_14" "flypy_18" "shuffle_17")) "double-pinyin"]
    [(member id '("luna_pinyin" "terra_pinyin" "pinyin_14")) "full-pinyin"]
    [(equal? id "cangjie6") "shape"]
    [(equal? id "jyut6ping3") "cantonese"]
    [(equal? id "bopomofo") "phonetic"]
    [else "other"]))

(define (schema-catalog-label catalog-id)
  (hash-ref (hash "double-pinyin" "Double Pinyin"
                  "full-pinyin" "Full Pinyin"
                  "shape" "Shape"
                  "cantonese" "Cantonese"
                  "phonetic" "Phonetic"
                  "other" "Other")
            catalog-id
            catalog-id))

(define (schema-options)
  (for/list ([id (in-list gui-schema-ids)])
    (define name (or (schema-module-ref id 'chinese-name #f)
                     (read-schema-name-from-yaml id)
                     id))
    (option id name (schema-catalog-id id))))

(define (cataloged-options options)
  (filter-map
   (lambda (catalog-id)
     (define items
       (filter (lambda (item)
                 (equal? (option-catalog item) catalog-id))
               options))
     (and (pair? items)
          (cons catalog-id (sort items string<? #:key option-id))))
   schema-catalog-order))

(define (option-label item)
  (format "~a    ~a" (option-name item) (option-id item)))

(define (selected-ids rows)
  (for/list ([row (in-list rows)]
             #:when (send (cdr row) get-value))
    (option-id (car row))))

(define (set-row-values! rows enabled?)
  (for ([row (in-list rows)])
    (send (cdr row) set-value enabled?)))

(define (set-buttons-enabled! buttons enabled?)
  (queue-callback
   (lambda ()
     (for ([button (in-list buttons)])
       (when button
         (send button enable enabled?))))))

(define (set-status! label text)
  (queue-callback
   (lambda ()
     (send label set-label text))))

(define (append-log! log-field text)
  (queue-callback
   (lambda ()
     (define old (send log-field get-value))
     (send log-field set-value
           (if (string=? old "")
               text
               (string-append old "\n" text))))))

(define (reset-log! log-field text)
  (queue-callback
   (lambda ()
     (send log-field set-value text))))

(define (with-buttons-disabled buttons thunk)
  (set-buttons-enabled! buttons #f)
  (dynamic-wind
    void
    thunk
    (lambda ()
      (set-buttons-enabled! buttons #t))))

(define (build-mobile-bundle! schemas)
  (define profile
    (hash 'schemas schemas
          'desktop? #f))
  (define profile-out (build-path output-dir mobile-output-name))
  (define skin-source-dir (build-path output-dir mobile-skins-output-name))
  (define zip-path (build-path output-dir (string-append app-profile-name "-mobile.zip")))
  (define-values (built-out built-zip _skin-dir)
    (build-bundle! profile
                   app-profile-name
                   profile-out
                   zip-path
                   #:skin-dir skin-source-dir))
  (values built-out built-zip))

(define (selected-skin-dir)
  (build-path output-dir mobile-skins-output-name))

(define (built-skin-ids skin-dir)
  (if (directory-exists? skin-dir)
      (sort
       (for/list ([entry (in-list (directory-list skin-dir))]
                  #:when (directory-exists? (build-path skin-dir entry)))
         (path->string entry))
       string<?)
      '()))

(define (run-build! schema-rows status log-field buttons)
  (thread
   (lambda ()
     (with-buttons-disabled
      buttons
      (lambda ()
        (with-handlers ([exn:fail?
                         (lambda (exn)
                           (define message (string-append "Build failed: " (exn-message exn)))
                           (set-status! status message)
                           (append-log! log-field message))])
          (define schemas (selected-ids schema-rows))
          (cond
            [(null? schemas)
             (set-status! status "Select at least one schema.")
             (append-log! log-field "Nothing selected.")]
            [else
             (reset-log! log-field (format "Selected schemas: ~a" (string-join schemas ", ")))
             (set-status! status "Building mobile bundle...")
             (append-log! log-field "Building mobile bundle...")
             (define-values (_profile-out zip-path) (build-mobile-bundle! schemas))
             (define skins (built-skin-ids (selected-skin-dir)))
             (define message (format "Built ZIP: ~a" (path->string zip-path)))
             (set-status! status message)
             (append-log! log-field message)
             (append-log! log-field
                          (if (pair? skins)
                              (format "Built skins for /Skins/: ~a" (string-join skins ", "))
                              "No skin folders built."))])))))))

(define (run-push! schema-rows url-field allow-delete include-big-dicts status log-field buttons)
  (thread
   (lambda ()
     (with-buttons-disabled
      buttons
      (lambda ()
        (with-handlers ([exn:fail?
                         (lambda (exn)
                           (define message (string-append "Push failed: " (exn-message exn)))
                           (set-status! status message)
                           (append-log! log-field message))])
          (define schemas (selected-ids schema-rows))
          (cond
            [(null? schemas)
             (set-status! status "Select at least one schema.")
             (append-log! log-field "Nothing selected.")]
            [else
             (define raw-url (string-trim (send url-field get-value)))
             (define base-url (and (not (string=? raw-url "")) raw-url))
             (reset-log! log-field (format "Selected schemas: ~a" (string-join schemas ", ")))
             (set-status! status "Building mobile bundle...")
             (append-log! log-field "Building mobile bundle...")
             (define-values (profile-out zip-path) (build-mobile-bundle! schemas))
             (define skin-source-dir (selected-skin-dir))
             (define skins (built-skin-ids skin-source-dir))
             (append-log! log-field (format "Built ZIP: ~a" (path->string zip-path)))
             (append-log! log-field
                          (if (pair? skins)
                              (format "Built skins for /Skins/: ~a" (string-join skins ", "))
                              "No skin folders built."))
             (set-status! status "Uploading to Yuanshu WiFi transfer...")
             (append-log! log-field
                          (if base-url
                              (format "Using Yuanshu URL: ~a" base-url)
                              "Scanning LAN for Yuanshu WiFi transfer..."))
             (do-upload! profile-out
                         #:base-url base-url
                         #:skin-source-dir skin-source-dir
                         #:allow-delete (send allow-delete get-value)
                         #:include-big-dicts (send include-big-dicts get-value)
                         #:progress (lambda (line) (append-log! log-field line)))
             (define done "Upload complete. Redeploy schemas and reselect the skin inside Yuanshu.")
             (set-status! status done)
             (append-log! log-field done)])))))))

(define (make-section parent catalog-id options default-ids)
  (define group
    (new group-box-panel%
         [label (schema-catalog-label catalog-id)]
         [parent parent]
         [alignment '(left top)]
         [spacing 4]
         [stretchable-height #f]))
  (define rows '())
  (for ([item (in-list options)])
    (define checkbox
      (new check-box%
           [label (option-label item)]
           [parent group]
           [value (and (member (option-id item) default-ids) #t)]))
    (set! rows (append rows (list (cons item checkbox)))))
  rows)

(define (start-gui)
  (define frame
    (new frame%
         [label "Rime Config"]
         [width 980]
         [height 620]))
  (define root
    (new vertical-panel%
         [parent frame]
         [alignment '(left top)]
         [spacing 10]
         [border 16]))

  (define content
    (new horizontal-panel%
         [parent root]
         [alignment '(left top)]
         [spacing 14]
         [stretchable-width #t]
         [stretchable-height #t]))

  (define schema-column
    (new group-box-panel%
         [label "Schemas"]
         [parent content]
         [alignment '(left top)]
         [spacing 8]
         [min-width 440]
         [stretchable-width #t]
         [stretchable-height #t]))

  (define top-actions
    (new horizontal-panel%
         [parent schema-column]
         [spacing 8]
         [stretchable-height #f]))

  (define schema-pane
    (new vertical-panel%
         [parent schema-column]
         [alignment '(left top)]
         [spacing 8]
         [stretchable-height #t]))

  (define schema-rows
    (append*
     (for/list ([catalog (in-list (cataloged-options (schema-options)))])
       (make-section schema-pane (car catalog) (cdr catalog) default-schema-ids))))

  (new button%
       [label "Select all shown"]
       [parent top-actions]
       [callback (lambda (_button _event) (set-row-values! schema-rows #t))])
  (new button%
       [label "Clear"]
       [parent top-actions]
       [callback (lambda (_button _event) (set-row-values! schema-rows #f))])
  (new button%
       [label "Flypy default"]
       [parent top-actions]
       [callback
        (lambda (_button _event)
          (set-row-values! schema-rows #f)
          (for ([row (in-list schema-rows)])
            (when (member (option-id (car row)) default-schema-ids)
              (send (cdr row) set-value #t))))])

  (define transfer-group
    (new group-box-panel%
         [label "iPhone Upload"]
         [parent content]
         [alignment '(left top)]
         [spacing 10]
         [min-width 420]
         [stretchable-width #t]
         [stretchable-height #t]))
  (define url-field
    (new text-field%
         [label "WiFi transfer URL"]
         [parent transfer-group]
         [init-value ""]
         [min-width 360]))
  (new message%
       [parent transfer-group]
       [label "Leave blank to scan LAN, or paste the URL from Yuanshu."])
  (define upload-options
    (new horizontal-panel%
         [parent transfer-group]
         [spacing 12]
         [stretchable-height #f]))
  (define allow-delete
    (new check-box%
         [label "Delete remote files not in this bundle"]
         [parent upload-options]
         [value #f]))
  (define include-big-dicts
    (new check-box%
         [label "Include large dictionaries"]
         [parent upload-options]
         [value #t]))

  (define status
    (new message%
         [parent transfer-group]
         [label "Ready."]
         [stretchable-width #t]))
  (define log-field
    (new text-field%
         [label "Status report"]
         [parent transfer-group]
         [init-value "Ready."]
         [style '(multiple)]
         [min-height 240]
         [stretchable-width #t]))

  (define actions
    (new horizontal-panel%
         [parent transfer-group]
         [spacing 8]
         [stretchable-height #f]))
  (define build-button #f)
  (define push-button #f)
  (define action-buttons '())
  (set! build-button
        (new button%
             [label "Build ZIP"]
             [parent actions]
             [callback
              (lambda (_button _event)
                (run-build! schema-rows status log-field action-buttons))]))
  (set! push-button
        (new button%
             [label "Push to iPhone"]
             [parent actions]
             [callback
              (lambda (_button _event)
                (run-push! schema-rows
                           url-field
                           allow-delete
                           include-big-dicts
                           status
                           log-field
                           action-buttons))]))
  (set! action-buttons (list build-button push-button))

  (send frame show #t))

(module+ main
  (start-gui))
