#lang racket/base

(require racket/cmdline
         racket/format
         racket/list
         racket/match
         racket/path
         racket/string
         racket/system
         "build/main.rkt"
         "build/k8s.rkt")

(define commands '(serve build k8s check-k8s dev gui))

(define (usage)
  (displayln "usage: racket main.rkt <command> [options]")
  (displayln "")
  (displayln "commands:")
  (displayln "  serve       Start the web app")
  (displayln "  build       Build a Rime/Yuanshu profile")
  (displayln "  k8s         Render deploy artifacts")
  (displayln "  check-k8s   Check generated deploy artifacts")
  (displayln "  dev         Run the web development watcher")
  (displayln "  gui         Open the native Yuanshu GUI"))

(define (command-symbol raw)
  (define sym (string->symbol raw))
  (and (member sym commands) sym))

(define (path-option raw)
  (and raw (string->path raw)))

(define (run-build args)
  (define schemas "all")
  (define artifact "yuanshu")
  (define out-dir #f)
  (define zip-path #f)
  (define profile-name "rime")
  (define render-docs? #t)
  (command-line
   #:program "racket main.rkt build"
   #:argv args
   #:once-each
   [("--schemas") value "Comma-separated schema ids, or all"
                  (set! schemas
                        (if (equal? value "all")
                            "all"
                            (filter (lambda (part)
                                      (not (string=? part "")))
                                    (string-split value ","))))]
   [("--schema") value "Add one schema id"
                 (set! schemas
                       (if (equal? schemas "all")
                           (list value)
                           (append schemas (list value))))]
   [("--artifact") value "Build artifact: yuanshu or rime"
                   (set! artifact value)]
   [("--out-dir") value "Output directory"
                 (set! out-dir (path-option value))]
   [("--zip") value "Optional ZIP output path"
            (set! zip-path (path-option value))]
   [("--profile-name") value "Profile directory name"
                       (set! profile-name value)]
   [("--no-docs") "Skip generated layout docs"
                  (set! render-docs? #f)]
   #:args ()
   (define-values (built-out built-zip _layout-dir _layouts)
     (build-output! #:schemas schemas
                    #:artifact artifact
                    #:out-dir (or out-dir output-dir)
                    #:profile-name profile-name
                    #:zip-path zip-path
                    #:render-docs? render-docs?))
   (printf "Built ~a profile at ~a\n" artifact (path->string built-out))
   (when built-zip
     (printf "Wrote ZIP at ~a\n" (path->string built-zip)))))

(define (run-dev)
  (define racket-exe
    (or (find-executable-path "racket")
        (error 'dev "racket not found in PATH")))
  (unless (system* racket-exe "build/serve.rkt")
    (error 'dev "build/serve.rkt failed")))

(define (run-gui)
  (define start-gui (dynamic-require "build/gui.rkt" 'start-gui))
  (start-gui))

(define (run-serve)
  (define start (dynamic-require "web/app.rkt" 'start))
  (start))

(define (run-command command args)
  (match command
    ['serve (when (pair? args)
              (error 'serve "unexpected arguments: ~a" (~a args)))
            (run-serve)]
    ['build (run-build args)]
    ['k8s (when (pair? args)
            (error 'k8s "unexpected arguments: ~a" (~a args)))
          (define deploy-dir (render-deploy-artifacts!))
          (printf "Rendered deploy artifacts: ~a\n"
                  (path->string deploy-dir))]
    ['check-k8s (when (pair? args)
                  (error 'check-k8s "unexpected arguments: ~a" (~a args)))
                (check-deploy-artifacts!)
                (displayln "Deploy artifacts are current.")]
    ['dev (when (pair? args)
            (error 'dev "unexpected arguments: ~a" (~a args)))
          (run-dev)]
    ['gui (when (pair? args)
            (error 'gui "unexpected arguments: ~a" (~a args)))
          (run-gui)]))

(define (run-cli [argv (current-command-line-arguments)])
  (define args (vector->list argv))
  (match args
    [(or '() (list "--help") (list "-h"))
     (usage)]
    [(cons raw-command rest)
     (define command (command-symbol raw-command))
     (unless command
       (usage)
       (error 'main "unknown command: ~a" raw-command))
     (run-command command (list->vector rest))]))

(module+ main
  (run-cli))
