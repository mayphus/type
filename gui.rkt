#lang racket/base

(require racket/class
         racket/gui/base
         racket/list
         racket/string
         "input-method/registry.rkt"
         "build.rkt")

(provide start-gui)

(struct option (id name catalog) #:transparent)

(define app-profile-name "input-foundry")
(define mobile-output-name "gui-mobile")
(define default-wifi-transfer-host "192.168.36.240")
(define default-schema-ids '("flypy"))
(define gui-schema-ids
  (remove-duplicates (append generated-config-ids (list-static-schema-ids))))

(define (schema-options)
  (for/list ([id (in-list gui-schema-ids)])
    (define name (or (schema-module-ref id 'chinese-name #f)
                     (read-schema-name-from-yaml id)
                     id))
    (option id name (schema-id->catalog-id id))))

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
  (option-name item))

(define (wifi-transfer-url raw)
  (define value (string-trim raw))
  (cond
    [(string=? value "") #f]
    [(or (string-prefix? value "http://")
         (string-prefix? value "https://"))
     value]
    [else (string-append "http://" value)]))

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
     (send label set-value text))))

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
  (define profile-out (build-path output-dir mobile-output-name))
  (define zip-path (build-path output-dir (string-append app-profile-name "-mobile.zip")))
  (define skin-dir (build-path output-dir (string-append mobile-output-name "-skins")))
  (define-values (built-out built-zip layout-dir _layouts)
    (build-output! #:schemas schemas
                   #:artifact "yuanshu"
                   #:out-dir profile-out
                   #:profile-name app-profile-name
                   #:zip-path zip-path
                   #:skin-dir skin-dir
                   #:skip-default-custom? #f))
  (values built-out built-zip layout-dir))

(define (built-keyboard-layout-ids layout-dir)
  (if (directory-exists? layout-dir)
      (sort
       (for/list ([entry (in-list (directory-list layout-dir))]
                  #:when (directory-exists? (build-path layout-dir entry)))
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
             (define-values (_profile-out zip-path layout-source-dir) (build-mobile-bundle! schemas))
             (define layouts (built-keyboard-layout-ids layout-source-dir))
             (define message (format "Built ZIP: ~a" (path->string zip-path)))
             (set-status! status message)
             (append-log! log-field message)
             (append-log! log-field
                          (if (pair? layouts)
                              (format "Built keyboard layouts for /Skins/: ~a" (string-join layouts ", "))
                              "No keyboard layout folders built."))])))))))

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
             (define base-url (wifi-transfer-url (send url-field get-value)))
             (reset-log! log-field (format "Selected schemas: ~a" (string-join schemas ", ")))
             (set-status! status "Building mobile bundle...")
             (append-log! log-field "Building mobile bundle...")
             (define-values (profile-out zip-path layout-source-dir) (build-mobile-bundle! schemas))
             (define layouts (built-keyboard-layout-ids layout-source-dir))
             (append-log! log-field (format "Built ZIP: ~a" (path->string zip-path)))
             (append-log! log-field
                          (if (pair? layouts)
                              (format "Built keyboard layouts for /Skins/: ~a" (string-join layouts ", "))
                              "No keyboard layout folders built."))
             (set-status! status "Uploading to Yuanshu WiFi transfer...")
             (append-log! log-field
                          (if base-url
                              (format "Using Yuanshu URL: ~a" base-url)
                              "Scanning LAN for Yuanshu WiFi transfer..."))
             (do-upload! profile-out
                         #:base-url base-url
                         #:skin-source-dir layout-source-dir
                         #:allow-delete (send allow-delete get-value)
                         #:include-big-dicts (send include-big-dicts get-value)
                         #:progress (lambda (line) (append-log! log-field line)))
             (define done "Upload complete. Redeploy schemas and reselect the keyboard layout inside Yuanshu.")
             (set-status! status done)
             (append-log! log-field done)])))))))

(define (make-section parent catalog-id options default-ids)
  (new message%
       [parent parent]
       [label (schema-catalog-label catalog-id)])
  (define rows '())
  (for ([item (in-list options)])
    (define checkbox
      (new check-box%
           [label (option-label item)]
           [parent parent]
           [value (and (member (option-id item) default-ids) #t)]))
    (set! rows (append rows (list (cons item checkbox)))))
  rows)

(define (lightest-column columns)
  (argmin cdr columns))

(define (add-catalog-to-column column catalog)
  (cons (cons catalog (car column))
        (+ (cdr column) (length (cdr catalog)))))

(define (split-catalogs catalogs column-count)
  (let loop ([remaining catalogs]
             [columns (for/list ([_ (in-range column-count)])
                        (cons '() 0))])
    (cond
      [(null? remaining)
       (map (lambda (column) (reverse (car column))) columns)]
      [else
       (define catalog (car remaining))
       (define target (lightest-column columns))
       (loop (cdr remaining)
             (for/list ([column (in-list columns)])
               (if (eq? column target)
                   (add-catalog-to-column column catalog)
                   column)))])))

(define (start-gui)
  (define frame
    (new frame%
         [label "Input Foundry"]
         [width 560]
         [height 400]))
  (define root
    (new vertical-panel%
         [parent frame]
         [alignment '(left top)]
         [spacing 3]
         [border 4]))

  (define connection-row
    (new horizontal-panel%
         [parent root]
         [alignment '(left center)]
         [spacing 4]
         [stretchable-width #t]
         [stretchable-height #f]))
  (new message% [parent connection-row] [label "Host"])
  (define url-field
    (new text-field%
         [label #f]
         [parent connection-row]
         [init-value default-wifi-transfer-host]
         [min-width 130]
         [stretchable-width #f]))
  (define build-button #f)
  (define push-button #f)
  (define action-buttons '())
  (set! build-button
        (new button%
             [label "Build"]
             [parent connection-row]
             [callback
              (lambda (_button _event)
                (run-build! schema-rows status log-field action-buttons))]))
  (set! push-button
        (new button%
             [label "Push"]
             [parent connection-row]
             [callback
              (lambda (_button _event)
                (run-push! schema-rows
                           url-field
                           allow-delete
                           include-big-dicts
                           status
                           log-field
                           action-buttons))]))
  (define allow-delete
    (new check-box%
         [label "Clean"]
         [parent connection-row]
         [value #f]))
  (define include-big-dicts
    (new check-box%
         [label "Dicts"]
         [parent connection-row]
         [value #t]))

  (define log-field
    (new text-field%
         [label #f]
         [parent root]
         [init-value "Ready."]
         [style '(multiple)]
         [min-height 34]
         [stretchable-width #t]
         [stretchable-height #f]))
  (define status log-field)

  (define schema-actions
    (new horizontal-panel%
         [parent root]
         [alignment '(left center)]
         [spacing 4]
         [stretchable-width #t]
         [stretchable-height #f]))
  (new button%
       [label "All"]
       [parent schema-actions]
       [callback (lambda (_button _event) (set-row-values! schema-rows #t))])
  (new button%
       [label "Clear"]
       [parent schema-actions]
       [callback (lambda (_button _event) (set-row-values! schema-rows #f))])

  (define schema-grid
    (new horizontal-panel%
         [parent root]
         [alignment '(left top)]
         [spacing 0]
         [stretchable-width #t]
         [stretchable-height #t]))
  (define schema-columns
    (for/list ([_ (in-range 3)])
      (new vertical-panel%
           [parent schema-grid]
           [alignment '(left top)]
           [spacing 1]
           [min-width 170]
           [stretchable-width #t]
           [stretchable-height #t])))

  (define catalog-columns
    (split-catalogs (cataloged-options (schema-options)) 3))
  (define schema-rows
    (append*
     (for/list ([column (in-list schema-columns)]
                [catalogs (in-list catalog-columns)])
       (append*
        (for/list ([catalog (in-list catalogs)])
          (make-section column (car catalog) (cdr catalog) default-schema-ids))))))

  (set! action-buttons (list build-button push-button))

  (send frame center)
  (send frame show #t))

(module+ main
  (start-gui))
