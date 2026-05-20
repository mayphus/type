#lang racket/base

(require json
         net/http-client
         racket/list
         racket/match
         racket/port
         racket/string)

(define hostname "type.mayphus.org")
(define service "http://192.168.36.236:80")
(define default-tunnel-id "28166ba0-3b51-4dc2-b46c-ea3feeabb262")

(define (env! name)
  (define value (getenv name))
  (when (or (not value) (string=? (string-trim value) ""))
    (error 'ensure-cloudflare-type-route "missing environment variable: ~a" name))
  value)

(define (getenv/default name default)
  (or (getenv name) default))

(define (normalized-token token)
  (define trimmed (string-trim token))
  (define without-assignment
    (regexp-replace #rx"(?i:^cloudflare_api_token[[:space:]]*=[[:space:]]*)" trimmed ""))
  (define without-header
    (regexp-replace #rx"(?i:^authorization:[[:space:]]*)" without-assignment ""))
  (define without-bearer
    (regexp-replace #rx"(?i:^bearer[[:space:]]+)" (string-trim without-header) ""))
  (regexp-replace* #rx"[[:space:]]+" (string-trim without-bearer "\"'") ""))

(define (tunnel-config-path account-id tunnel-id)
  (format "/client/v4/accounts/~a/cfd_tunnel/~a/configurations"
          account-id
          tunnel-id))

(define (cloudflare-request method path token [payload #f])
  (define body-bytes
    (and payload (string->bytes/utf-8 (jsexpr->string payload))))
  (define headers
    (append
     (list (format "Authorization: Bearer ~a" (normalized-token token))
           "Content-Type: application/json")
     (if body-bytes
         (list (format "Content-Length: ~a" (bytes-length body-bytes)))
         '())))
  (define-values (status _headers in)
    (http-sendrecv "api.cloudflare.com"
                   path
                   #:ssl? #t
                   #:method method
                   #:headers headers
                   #:data body-bytes))
  (define status-line
    (if (bytes? status) (bytes->string/utf-8 status) status))
  (define body (port->string in))
  (define parsed
    (if (string=? (string-trim body) "")
        (hash)
        (with-input-from-string body read-json)))
  (unless (regexp-match? #rx" 2[0-9][0-9] " status-line)
    (error 'ensure-cloudflare-type-route
           "~a ~a failed with ~a\n~a"
           method path status-line body))
  (when (eq? (hash-ref parsed 'success #t) #f)
    (error 'ensure-cloudflare-type-route
           "~a ~a failed\n~a"
           method path body))
  parsed)

(define (hostname-rule? rule)
  (equal? hostname (hash-ref rule 'hostname #f)))

(define (fallback-rule? rule)
  (not (hash-has-key? rule 'hostname)))

(define type-route
  (hash 'hostname hostname
        'service service))

(define (ensure-type-route ingress)
  (define without-type
    (filter (lambda (rule) (not (hostname-rule? rule))) ingress))
  (define-values (before-fallback fallback-and-after)
    (splitf-at without-type (lambda (rule) (not (fallback-rule? rule)))))
  (append before-fallback (list type-route) fallback-and-after))

(define (print-ingress ingress)
  (for ([rule (in-list ingress)])
    (printf "- ~a => ~a\n"
            (hash-ref rule 'hostname "<fallback>")
            (hash-ref rule 'service))))

(module+ main
  (define account-id (env! "CLOUDFLARE_ACCOUNT_ID"))
  (define api-token (env! "CLOUDFLARE_API_TOKEN"))
  (define tunnel-id (getenv/default "CLOUDFLARED_TUNNEL_ID" default-tunnel-id))
  (define path (tunnel-config-path account-id tunnel-id))
  (define current (cloudflare-request "GET" path api-token))
  (define config (hash-ref (hash-ref current 'result) 'config))
  (define ingress (hash-ref config 'ingress))
  (define next-ingress (ensure-type-route ingress))
  (if (equal? ingress next-ingress)
      (begin
        (printf "Cloudflare tunnel route already present for ~a\n" hostname)
        (print-ingress ingress))
      (let ([updated
             (cloudflare-request "PUT"
                                 path
                                 api-token
                                 (hash 'config
                                       (hash-set config 'ingress next-ingress)))])
        (printf "Updated Cloudflare tunnel config version ~a\n"
                (hash-ref (hash-ref updated 'result) 'version))
        (print-ingress
         (hash-ref (hash-ref (hash-ref updated 'result) 'config) 'ingress)))))
