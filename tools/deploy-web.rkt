#lang racket/base

;;; tools/deploy-web.rkt — Deploy / update the Input Foundry web app on a remote Podman host.
;;;
;;; Usage:
;;;   racket tools/deploy-web.rkt [options]
;;;
;;; Options:
;;;   --host       SSH hostname                      (default: raspberrypi)
;;;   --host-port  host port to bind                 (default: 5002)
;;;   --cont-port  container internal port / PORT    (default: 8080)
;;;   --dir        repo path on remote               (default: ~/input-foundry)
;;;   --name       container/image name              (default: input-foundry)
;;;
;;; What it does:
;;;   1. git pull on the remote
;;;   2. podman build
;;;   3. stop + remove old container (if running)
;;;   4. podman run with --restart=always

(require racket/cmdline
         racket/system
         racket/string)

(provide deploy!)

(define ssh-exe (or (find-executable-path "ssh")
                    (error 'deploy-web "ssh not found in PATH")))

;; Run an SSH command; error on failure.
(define (ssh! host cmd)
  (printf "  >> ~a\n" cmd)
  (unless (system* ssh-exe host cmd)
    (error 'deploy-web "command failed on ~a: ~a" host cmd)))

;; Run an SSH command; ignore non-zero exit (for stop/rm).
(define (ssh/ignore host cmd)
  (printf "  >> ~a\n" cmd)
  (system* ssh-exe host cmd))

(define (deploy! host host-port cont-port dir name)
  (define hport (number->string host-port))
  (define cport (number->string cont-port))

  (printf "\n[1/4] Pulling latest changes on ~a:~a ...\n" host dir)
  (ssh! host (string-append "cd " dir " && git pull"))

  (printf "\n[2/4] Building image '~a' ...\n" name)
  (ssh! host (string-append "cd " dir " && podman build -t " name " ."))

  (printf "\n[3/4] Stopping old container (if any) ...\n")
  (ssh/ignore host (string-append "podman stop " name " 2>/dev/null || true"))
  (ssh/ignore host (string-append "podman rm   " name " 2>/dev/null || true"))

  (printf "\n[4/4] Starting new container ...\n")
  (ssh! host
        (string-join
         (list "podman run -d"
               "--name"          name
               "--restart=always"
               "-p"              (string-append hport ":" cport)
               "-e"              (string-append "PORT=" cport)
               "-e"              "LISTEN_IP=0.0.0.0"
               name)
         " "))

  (printf "\nDone. Input Foundry available at http://~a:~a\n\n" host host-port))

(module+ main
  (define opt-host      (make-parameter "raspberrypi"))
  (define opt-host-port (make-parameter 5002))
  (define opt-cont-port (make-parameter 8080))
  (define opt-dir       (make-parameter "~/input-foundry"))
  (define opt-name      (make-parameter "input-foundry"))

  (command-line
   #:program "deploy-web.rkt"
   #:once-each
   [("--host")      h "SSH hostname (default: raspberrypi)"                  (opt-host h)]
   [("--host-port") p "Host port to bind (default: 5002)"                    (opt-host-port (string->number p))]
   [("--cont-port") p "Container internal port / PORT env (default: 8080)"   (opt-cont-port (string->number p))]
   [("--dir")       d "Repo path on remote (default: ~/input-foundry)"         (opt-dir d)]
   [("--name")      n "Container/image name (default: input-foundry)"          (opt-name n)]
   #:args ()
   (deploy! (opt-host) (opt-host-port) (opt-cont-port) (opt-dir) (opt-name))))
