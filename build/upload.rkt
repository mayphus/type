#lang racket/base

(require "../tools/yuanshu-sync.rkt")

(provide do-upload!)

(define (do-upload! src-dir
                    #:remote-root     [remote-root "/RimeUserData/rime/"]
                    #:base-url        [base-url #f]
                    #:skin-source-dir [skin-source-dir #f]
                    #:allow-delete    [allow-delete #f]
                    #:include-big-dicts [include-big-dicts #t]
                    #:dry-run         [dry-run #f]
                    #:progress        [progress (lambda (_line) (void))])
  (define exclude-dirs
    (if include-big-dicts '() '("jyut6ping3_dicts" "rime_ice_dicts")))
  (parameterize ([current-yuanshu-sync-log progress])
    (sync-yuanshu-bundle! src-dir
                          #:remote-root remote-root
                          #:base-url base-url
                          #:allow-delete? allow-delete
                          #:dry-run? dry-run
                          #:exclude-dirs exclude-dirs)
    (when skin-source-dir
      (progress "Refreshing selected Yuanshu /Skins/ folders...")
      (sync-yuanshu-skins! skin-source-dir
                           #:remote-root "/Skins/"
                           #:base-url base-url
                           #:dry-run? dry-run))))
