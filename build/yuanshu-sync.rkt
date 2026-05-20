#lang racket/base

;;; Sync a built Yuanshu bundle to the app's WiFi file service.

(require json
         net/http-client
         net/uri-codec
         net/url
         openssl/sha1
         racket/cmdline
         racket/file
         racket/format
         racket/list
         racket/match
         racket/path
         racket/port
         racket/set
         racket/string)

(provide sync-yuanshu-bundle!
         sync-yuanshu-skins!
         discover-base-urls
         normalize-remote-root
         current-yuanshu-sync-log)

(define default-remote-root "/RimeUserData/rime/")
(define manifest-basename "yuanshu-sync-manifest")
(define default-preserve-exact '("default.custom.yaml" "installation.yaml" "user.yaml"))
(define default-preserve-dirs '("build" "sync"))
(define default-discovery-candidates '())
(define current-yuanshu-sync-log (make-parameter (lambda (_line) (void))))

(struct remote-item (rel-path dir? size) #:transparent)

(define (info fmt . args)
  (define line (apply format fmt args))
  (eprintf "~a\n" line)
  ((current-yuanshu-sync-log) line))

(define (sync-error fmt . args)
  (apply error 'yuanshu-sync fmt args))

(define (normalize-remote-root path)
  (define raw (if (or (not path) (string=? path "")) default-remote-root path))
  (define prefixed (if (string-prefix? raw "/") raw (string-append "/" raw)))
  (if (string-suffix? prefixed "/") prefixed (string-append prefixed "/")))

(define (normalize-rel-path rel-path)
  (string-trim rel-path "/"))

(define (ensure-dir-path path)
  (if (string-suffix? path "/") path (string-append path "/")))

(define (normalize-remote-path path)
  (define trailing? (string-suffix? path "/"))
  (define absolute (if (string-prefix? path "/") path (string-append "/" path)))
  (define parts
    (for/fold ([parts '()])
              ([part (in-list (string-split absolute "/"))])
      (cond
        [(or (string=? part "") (string=? part ".")) parts]
        [(string=? part "..") (if (null? parts) parts (cdr parts))]
        [else (cons part parts)])))
  (define normalized (string-append "/" (string-join (reverse parts) "/")))
  (cond
    [(and trailing? (not (string=? normalized "/")))
     (string-append normalized "/")]
    [else normalized]))

(define (encode-remote-path path)
  (define normalized (normalize-remote-path path))
  (define trailing? (and (string-suffix? normalized "/") (not (string=? normalized "/"))))
  (define encoded
    (string-append
     "/"
     (string-join
      (for/list ([part (in-list (string-split normalized "/"))]
                 #:unless (string=? part ""))
        (uri-encode part))
      "/")))
  (cond
    [(string=? encoded "/") encoded]
    [trailing? (string-append encoded "/")]
    [else encoded]))

(define (join-remote root rel-path #:dir? [dir? #f])
  (define root* (normalize-remote-root root))
  (define joined
    (if (string=? (normalize-rel-path rel-path) "")
        root*
        (string-append root* (normalize-rel-path rel-path))))
  (if dir? (ensure-dir-path joined) joined))

(define (query-string query)
  (if (null? query)
      ""
      (string-append
       "?"
       (string-join
        (for/list ([entry (in-list query)])
          (format "~a=~a" (uri-encode (car entry)) (uri-encode (cdr entry))))
        "&"))))

(define (api-target api-root remote-path [query '()])
  (string-append api-root (encode-remote-path remote-path) (query-string query)))

(define (base-url-parts base-url)
  (define url (string->url (string-trim base-url "/" #:left? #f #:right? #t)))
  (define scheme (url-scheme url))
  (define host (url-host url))
  (unless (and host (member scheme '("http" "https")))
    (sync-error "invalid Yuanshu base URL: ~a" base-url))
  (values scheme
          host
          (or (url-port url) (if (equal? scheme "https") 443 80))
          (equal? scheme "https")))

(define (status-code status)
  (cond
    [(bytes? status)
     (status-code (bytes->string/utf-8 status))]
    [(regexp-match #rx"^[^ ]+ ([0-9][0-9][0-9])" status)
     => (lambda (m) (string->number (cadr m)))]
    [else #f]))

(define (headers->hash headers)
  (for/hash ([header (in-list headers)])
    (define text (if (bytes? header) (bytes->string/utf-8 header) header))
    (match (regexp-match #rx"^([^:]+):[ ]*(.*)$" text)
      [(list _ key value) (values (string-titlecase key) value)]
      [_ (values text "")])))

(define (http-request base-url target
                      #:method [method "GET"]
                      #:data [data #f]
                      #:headers [headers '()]
                      #:timeout [_timeout 10.0]
                      #:retries [retries 3])
  ;; net/http-client does not expose a per-request timeout in this simple API.
  (define-values (_scheme host port ssl?) (base-url-parts base-url))
  (let loop ([attempt 1] [last-error #f])
    (with-handlers ([exn:fail?
                     (lambda (exn)
                       (if (< attempt retries)
                           (begin
                             (sleep (* 0.3 attempt))
                             (loop (add1 attempt) exn))
                           (sync-error "~a ~a failed: ~a"
                                       method
                                       (string-append (string-trim base-url "/" #:left? #f #:right? #t) target)
                                       (exn-message (or last-error exn)))))])
      (define-values (status response-headers in)
        (http-sendrecv host
                       target
                       #:port port
                       #:ssl? ssl?
                       #:method method
                       #:headers headers
                       #:data (or data #"")))
      (define body (port->bytes in))
      (close-input-port in)
      (define code (status-code status))
      (cond
        [(and code (<= 200 code 299))
         (values body code (headers->hash response-headers))]
        [(and code (>= code 500) (< attempt retries))
         (sleep (* 0.3 attempt))
         (loop (add1 attempt) #f)]
        [else
         (sync-error "~a ~a failed with HTTP ~a: ~a"
                     method
                     (string-append (string-trim base-url "/" #:left? #f #:right? #t) target)
                     (or code status)
                     (string-trim (bytes->string/utf-8 body #\?)))]))))

(define (http-json base-url target #:timeout [timeout 10.0] #:retries [retries 3])
  (define-values (body _status headers)
    (http-request base-url target #:timeout timeout #:retries retries))
  (with-handlers ([exn:fail?
                   (lambda (exn)
                     (sync-error "GET ~a returned invalid JSON: ~a"
                                 (string-append base-url target)
                                 (exn-message exn)))])
    (values (bytes->jsexpr body) headers)))

(define (list-remote-dir base-url remote-dir)
  (define-values (payload _headers)
    (http-json base-url (api-target "/api/resources" remote-dir)))
  (for/list ([item (in-list (hash-ref payload 'items '()))])
    (remote-item (hash-ref item 'name)
                 (and (hash-ref item 'isDir #f) #t)
                 (hash-ref item 'size 0))))

(define (create-remote-dir base-url remote-dir)
  (http-request base-url
                (api-target "/api/resources" remote-dir '(("override" . "false")))
                #:method "POST"
                #:data #""
                #:timeout 15.0)
  (void))

(define (delete-remote-path base-url remote-path dir?)
  (http-request base-url
                (api-target "/api/resources" (if dir? (ensure-dir-path remote-path) remote-path))
                #:method "DELETE"
                #:timeout 15.0)
  (void))

(define (tus-upload-bytes base-url remote-file data)
  (define size (bytes-length data))
  (define target (api-target "/api/tus" remote-file '(("override" . "true"))))
  (http-request base-url
                target
                #:method "POST"
                #:data #""
                #:headers (list "Tus-Resumable: 1.0.0"
                                (format "Upload-Length: ~a" size))
                #:timeout 20.0)
  (http-request base-url
                target
                #:method "PATCH"
                #:data data
                #:headers (list "Tus-Resumable: 1.0.0"
                                "Upload-Offset: 0"
                                "Content-Type: application/offset+octet-stream")
                #:timeout (max 30.0 (/ size (* 256 1024.0))))
  (void))

(define (tus-upload-file base-url remote-file local-file)
  (tus-upload-bytes base-url remote-file (file->bytes local-file)))

(define (path-matches-dir-prefix? rel-path prefixes)
  (define clean (normalize-rel-path rel-path))
  (for/or ([prefix (in-list prefixes)])
    (or (string=? clean prefix)
        (string-prefix? clean (string-append prefix "/")))))

(define (preserved? rel-path)
  (define clean (normalize-rel-path rel-path))
  (or (member clean default-preserve-exact)
      (path-matches-dir-prefix? clean default-preserve-dirs)
      (for/or ([part (in-list (string-split clean "/"))])
        (string-suffix? part ".userdb"))))

(define (path->rel-string source-dir path)
  (path->string (find-relative-path source-dir path)))

(define (build-local-tree source-dir excluded-dirs)
  (define local-dirs (mutable-set))
  (define local-files (mutable-set))
  (let walk ([dir source-dir] [rel-root ""])
    (for ([entry (in-list (sort (directory-list dir) path<?))])
      (define full (build-path dir entry))
      (define rel (if (string=? rel-root "")
                      (path->string entry)
                      (string-append rel-root "/" (path->string entry))))
      (unless (path-matches-dir-prefix? rel excluded-dirs)
        (cond
          [(directory-exists? full)
           (set-add! local-dirs rel)
           (walk full rel)]
          [(file-exists? full)
           (set-add! local-files rel)]))))
  (values (set->list local-dirs) (set->list local-files)))

(define (bytes->hex bytes)
  (apply string-append
         (for/list ([byte (in-bytes bytes)])
           (define hex (number->string byte 16))
           (if (= (string-length hex) 1)
               (string-append "0" hex)
               hex))))

(define (hash-file path)
  (call-with-input-file path
    (lambda (in) (bytes->hex (sha256-bytes in)))))

(define (json-string value)
  (jsexpr->string value))

(define (build-manifest source-dir local-files)
  (for/list ([rel (in-list (sort local-files string<?))])
    (define local-file (build-path source-dir rel))
    (list rel (file-size local-file) (hash-file local-file))))

(define (encode-manifest manifest)
  (string->bytes/utf-8
   (string-append
    "{\"files\":{"
    (string-join
     (for/list ([entry (in-list manifest)])
       (match-define (list rel size sha256) entry)
       (format "~a:{\"sha256\":~a,\"size\":~a}"
               (json-string rel)
               (json-string sha256)
               size))
     ",")
    "},\"version\":1}")))

(define (manifest-filename manifest-bytes)
  (format "~a.~a.json"
          manifest-basename
          (substring (bytes->hex (sha256-bytes (open-input-bytes manifest-bytes))) 0 16)))

(define (manifest-marker? rel-path)
  (define clean (normalize-rel-path rel-path))
  (and (not (string-contains? clean "/"))
       (string-prefix? clean (string-append manifest-basename "."))
       (string-suffix? clean ".json")))

(define (walk-remote-tree base-url remote-root excluded-dirs)
  (define remote-dirs (make-hash))
  (define remote-files (make-hash))
  (let loop ([stack (list (cons remote-root ""))])
    (match stack
      ['() (values remote-dirs remote-files)]
      [(cons current rest)
       (define current-remote (car current))
       (define rel-root (cdr current))
       (define next-stack rest)
       (for ([item (in-list (list-remote-dir base-url current-remote))])
         (define rel (if (string=? rel-root "")
                         (remote-item-rel-path item)
                         (string-append rel-root "/" (remote-item-rel-path item))))
         (cond
           [(remote-item-dir? item)
            (hash-set! remote-dirs rel (remote-item rel #t (remote-item-size item)))
            (unless (or (preserved? rel) (path-matches-dir-prefix? rel excluded-dirs))
              (set! next-stack
                    (cons (cons (join-remote remote-root rel #:dir? #t) rel)
                          next-stack)))]
           [else
            (hash-set! remote-files rel (remote-item rel #f (remote-item-size item)))]))
       (loop next-stack)])))

(define (command-output exe . args)
  (with-handlers ([exn:fail? (lambda (_) #f)])
    (define-values (proc out in err)
      (apply subprocess #f #f #f exe args))
    (close-output-port in)
    (define output (port->string out))
    (define error-output (port->string err))
    (close-input-port out)
    (close-input-port err)
    (subprocess-wait proc)
    (and (zero? (subprocess-status proc))
         (string-append output error-output))))

(define (parse-arp-candidates)
  (define output (command-output (or (find-executable-path "arp") "arp") "-an"))
  (if output
      (map cadr (regexp-match* #rx"\\(([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)\\)" output #:match-select values))
      '()))

(define (ipv4->int ip)
  (match (map string->number (string-split ip "."))
    [(list a b c d)
     (+ (arithmetic-shift a 24)
        (arithmetic-shift b 16)
        (arithmetic-shift c 8)
        d)]
    [_ #f]))

(define (int->ipv4 n)
  (format "~a.~a.~a.~a"
          (bitwise-and (arithmetic-shift n -24) #xff)
          (bitwise-and (arithmetic-shift n -16) #xff)
          (bitwise-and (arithmetic-shift n -8) #xff)
          (bitwise-and n #xff)))

(define (hex-mask->prefix mask)
  (define n (string->number (regexp-replace #rx"^0x" mask "") 16))
  (and n
       (for/sum ([i (in-range 32)])
         (if (bitwise-bit-set? n (- 31 i)) 1 0))))

(define (subnet-hosts ip mask)
  (define ip-int (ipv4->int ip))
  (define prefix (hex-mask->prefix mask))
  (cond
    [(not (and ip-int prefix)) '()]
    [else
     (define effective-prefix (if (< prefix 24) 24 prefix))
     (define host-count (expt 2 (- 32 effective-prefix)))
     (define mask-int (bitwise-and #xffffffff (arithmetic-shift #xffffffff (- 32 effective-prefix))))
     (define network (bitwise-and ip-int mask-int))
     (for/list ([n (in-range (add1 network) (- (+ network host-count) 1))])
       (int->ipv4 n))]))

(define (parse-active-subnet-hosts)
  (define output (command-output (or (find-executable-path "ifconfig") "ifconfig")))
  (if (not output)
      '()
      (let ([hosts '()]
            [current-iface #f]
            [current-ip #f]
            [current-mask #f]
            [current-active? #f])
        (define (flush!)
          (when (and current-active?
                     current-ip
                     current-mask
                     current-iface
                     (not (member current-iface '("lo0")))
                     (not (string-prefix? current-iface "utun")))
            (set! hosts (append (subnet-hosts current-ip current-mask) hosts)))
          (set! current-iface #f)
          (set! current-ip #f)
          (set! current-mask #f)
          (set! current-active? #f))
        (for ([raw-line (in-list (string-split output "\n"))])
          (define line (string-trim raw-line #:left? #f #:right? #t))
          (cond
            [(and (not (string-prefix? line "\t"))
                  (regexp-match? #rx": flags=" line))
             (flush!)
             (set! current-iface (car (string-split line ":")))]
            [current-iface
             (define stripped (string-trim line))
             (match (regexp-match #rx"inet ([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+) netmask (0x[0-9a-fA-F]+)" stripped)
               [(list _ ip mask)
                (set! current-ip ip)
                (set! current-mask mask)]
               [_ (when (string=? stripped "status: active")
                    (set! current-active? #t))])]))
        (flush!)
        (remove-duplicates (reverse hosts)))))

(define (candidate-hosts)
  (remove-duplicates
   (append default-discovery-candidates
           (parse-arp-candidates)
           (parse-active-subnet-hosts))))

(define (probe-base-url base-url #:timeout [timeout 1.5])
  (with-handlers ([exn:fail? (lambda (_) #f)])
    (define-values (payload headers)
      (http-json (string-trim base-url "/" #:left? #f #:right? #t)
                 "/api/resources/"
                 #:timeout timeout
                 #:retries 1))
    (and (string-contains? (hash-ref headers "Server" "") "GCDWebServer")
         (for/or ([item (in-list (hash-ref payload 'items '()))])
           (and (equal? (hash-ref item 'name #f) "RimeUserData")
                (hash-ref item 'isDir #f))))))

(define (discover-parallel hosts)
  (define jobs (make-channel))
  (define results (make-channel))
  (define worker-count (min 24 (max 1 (length hosts))))
  (for ([_ (in-range worker-count)])
    (thread
     (lambda ()
       (let loop ()
         (define host (channel-get jobs))
         (unless (eq? host 'done)
           (define url (string-append "http://" host))
           (when (probe-base-url url)
             (channel-put results url))
           (channel-put results #f)
           (loop))))))
  (for ([host (in-list hosts)]) (channel-put jobs host))
  (for ([_ (in-range worker-count)]) (channel-put jobs 'done))
  (filter values (for/list ([_ (in-range (length hosts))]) (channel-get results))))

(define (discover-base-urls #:base-url [explicit #f])
  (cond
    [explicit
     (unless (probe-base-url explicit #:timeout 3.0)
       (sync-error "Configured Yuanshu base URL is not reachable: ~a" explicit))
     (list (string-trim explicit "/" #:left? #f #:right? #t))]
    [else
     (define candidates '())
     (define env-base-url (getenv "YUANSHU_BASE_URL"))
     (when (and env-base-url (probe-base-url env-base-url #:timeout 3.0))
       (set! candidates (cons (string-trim env-base-url "/" #:left? #f #:right? #t) candidates)))
     (define env-host (getenv "YUANSHU_HOST"))
     (when env-host
       (define candidate
         (if (or (string-prefix? env-host "http://")
                 (string-prefix? env-host "https://"))
             env-host
             (string-append "http://" env-host)))
       (when (probe-base-url candidate #:timeout 3.0)
         (set! candidates (cons (string-trim candidate "/" #:left? #f #:right? #t) candidates))))
     (cond
       [(pair? candidates) (reverse candidates)]
       [else
        (define hosts (candidate-hosts))
        (info "Discovering Yuanshu hosts across ~a LAN candidates..." (length hosts))
        (define valid-urls (discover-parallel hosts))
        (when (null? valid-urls)
          (sync-error "Unable to discover any reachable Yuanshu WiFi transfer hosts"))
        valid-urls])]))

(define (sync-yuanshu-bundle! source-dir
                              #:remote-root [remote-root default-remote-root]
                              #:base-url [base-url #f]
                              #:dry-run? [dry-run? #f]
                              #:allow-delete? [allow-delete? #f]
                              #:use-manifest? [use-manifest? #t]
                              #:exclude-dirs [excluded-dirs '()])
  (define source (simplify-path (path->complete-path source-dir)))
  (unless (directory-exists? source)
    (sync-error "Source directory does not exist: ~a" source))
  (define roots (discover-base-urls #:base-url base-url))
  (define root (normalize-remote-root remote-root))
  (define excludes
    (filter (lambda (item) (not (string=? item "")))
            (map normalize-rel-path excluded-dirs)))
  (for ([url (in-list roots)])
    (info "--- Syncing to ~a ---" url)
    (sync-one-bundle! source url root dry-run? allow-delete? use-manifest? excludes)))

(define (local-skin-dirs source)
  (sort
   (for/list ([entry (in-list (directory-list source))]
              #:when (directory-exists? (build-path source entry)))
     (path->string entry))
   string<?))

(define (sync-yuanshu-skins! source-dir
                             #:remote-root [remote-root "/Skins/"]
                             #:base-url [base-url #f]
                             #:dry-run? [dry-run? #f])
  (define source (simplify-path (path->complete-path source-dir)))
  (unless (directory-exists? source)
    (sync-error "Skin source directory does not exist: ~a" source))
  (define selected-skins (local-skin-dirs source))
  (define roots (discover-base-urls #:base-url base-url))
  (define root (normalize-remote-root remote-root))
  (for ([url (in-list roots)])
    (info "--- Syncing selected skins to ~a ---" url)
    (info "Using Yuanshu host: ~a" url)
    (info "Sync source: ~a" source)
    (info "Sync destination: ~a" root)
    (define remote-root-items (list-remote-dir url root))
    (define remote-skin-set
      (list->set
       (for/list ([item (in-list remote-root-items)]
                  #:when (remote-item-dir? item))
         (remote-item-rel-path item))))
    (info "Skin plan: ~a selected skin refresh(es); all other skins preserved"
          (length selected-skins))
    (for ([skin (in-list selected-skins)])
      (define remote-dir (join-remote root skin #:dir? #t))
      (when (set-member? remote-skin-set skin)
        (info "DELETE selected skin ~a" skin)
        (unless dry-run?
          (delete-remote-path url remote-dir #t)))
      (unless dry-run?
        (create-remote-dir url remote-dir))
      (info "SYNC selected skin ~a" skin)
      (sync-one-bundle! (build-path source skin)
                        url
                        remote-dir
                        dry-run?
                        #t
                        #f
                        '()))))

(define (sync-one-bundle! source-dir base-url remote-root dry-run? allow-delete? use-manifest? excluded-dirs)
  (define-values (local-dirs local-files) (build-local-tree source-dir excluded-dirs))
  (define local-dir-set (list->set local-dirs))
  (define local-file-set (list->set local-files))
  (define manifest (and use-manifest? (build-manifest source-dir local-files)))
  (define manifest-bytes (and manifest (encode-manifest manifest)))
  (define current-manifest-file (and manifest-bytes (manifest-filename manifest-bytes)))
  (info "Using Yuanshu host: ~a" base-url)
  (info "Sync source: ~a" source-dir)
  (info "Sync destination: ~a" remote-root)
  (unless (null? excluded-dirs)
    (info "Excluded directories: ~a" (string-join (sort excluded-dirs string<?) ", ")))

  (define-values (remote-dirs remote-files) (walk-remote-tree base-url remote-root excluded-dirs))
  (define remote-manifest-files
    (sort (filter manifest-marker? (hash-keys remote-files)) string<?))
  (define stale-manifest-files
    (if use-manifest?
        (filter (lambda (rel) (not (string=? rel current-manifest-file))) remote-manifest-files)
        '()))

  (define deletions
    (sort
     (append
      (for/list ([(rel _item) (in-hash remote-files)]
                 #:unless (or (and use-manifest? (manifest-marker? rel))
                              (preserved? rel)
                              (path-matches-dir-prefix? rel excluded-dirs)
                              (set-member? local-file-set rel)))
        (cons rel #f))
      (for/list ([(rel _item) (in-hash remote-dirs)]
                 #:unless (or (preserved? rel)
                              (path-matches-dir-prefix? rel excluded-dirs)
                              (set-member? local-dir-set rel)))
        (cons rel #t)))
     >
     #:key (lambda (entry) (length (string-split (car entry) "/")))))

  (define creates
    (sort (filter (lambda (rel) (not (hash-has-key? remote-dirs rel))) local-dirs) string<?))
  (define manifest-map
    (if use-manifest?
        (for/hash ([entry (in-list manifest)])
          (match-define (list rel size _sha256) entry)
          (values rel size))
        (hash)))
  (define bundle-in-sync?
    (and use-manifest?
         (member current-manifest-file remote-manifest-files)
         (for/and ([rel (in-list local-files)])
           (define item (hash-ref remote-files rel #f))
           (and item (= (remote-item-size item) (hash-ref manifest-map rel))))))
  (define uploads (if bundle-in-sync? '() (sort local-files string<?)))
  (define manifest-changed? (and use-manifest? (not bundle-in-sync?)))

  (info "Plan: ~a delete(s), ~a dir create(s), ~a file upload(s), ~a marker cleanup(s)"
        (if allow-delete? (length deletions) 0)
        (length creates)
        (+ (length uploads) (if manifest-changed? 1 0))
        (length stale-manifest-files))
  (when (and (pair? deletions) (not allow-delete?))
    (info "Prune disabled; remote-only files will be left untouched. Use --allow-delete to remove them."))

  (when allow-delete?
    (for ([entry (in-list deletions)])
      (define rel (car entry))
      (define dir? (cdr entry))
      (info "DELETE ~a ~a" (if dir? "dir" "file") rel)
      (unless dry-run?
        (delete-remote-path base-url (join-remote remote-root rel #:dir? dir?) dir?))))

  (for ([rel (in-list creates)])
    (info "MKDIR ~a" rel)
    (unless dry-run?
      (create-remote-dir base-url (join-remote remote-root rel #:dir? #t))))

  (for ([rel (in-list stale-manifest-files)])
    (info "DELETE file ~a" rel)
    (unless dry-run?
      (delete-remote-path base-url (join-remote remote-root rel) #f)))

  (for ([rel (in-list uploads)])
    (info "UPLOAD ~a" rel)
    (unless dry-run?
      (tus-upload-file base-url (join-remote remote-root rel) (build-path source-dir rel))))

  (when manifest-changed?
    (info "UPLOAD ~a" current-manifest-file)
    (unless dry-run?
      (tus-upload-bytes base-url
                        (join-remote remote-root current-manifest-file)
                        manifest-bytes))))

(module+ main
  (define source #f)
  (define remote-root default-remote-root)
  (define base-url #f)
  (define dry-run? #f)
  (define allow-delete? #f)
  (define exclude-dirs '())
  (command-line
   #:program "yuanshu-sync.rkt"
   #:once-each
   [("--source") path "Local bundle directory to upload" (set! source path)]
   [("--remote-root") path "Remote Yuanshu directory root" (set! remote-root path)]
   [("--base-url") url "Explicit Yuanshu WiFi base URL" (set! base-url url)]
   [("--dry-run") "Show the sync plan without modifying the phone" (set! dry-run? #t)]
   [("--allow-delete") "Delete remote files and directories not present locally" (set! allow-delete? #t)]
   #:multi
   [("--exclude-dir") dir "Relative directory under the bundle root to leave untouched" (set! exclude-dirs (cons dir exclude-dirs))]
   #:args ()
   (unless source
     (sync-error "--source is required"))
   (sync-yuanshu-bundle! source
                         #:remote-root remote-root
                         #:base-url base-url
                         #:dry-run? dry-run?
                         #:allow-delete? allow-delete?
                         #:exclude-dirs (reverse exclude-dirs))))
