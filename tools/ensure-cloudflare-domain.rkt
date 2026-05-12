#lang racket/base

(require json
         racket/list
         racket/match
         racket/port
         racket/string
         racket/system)

(define zone-name "mayphus.org")
(define hostname "type.mayphus.org")
(define tunnel-id "28166ba0-3b51-4dc2-b46c-ea3feeabb262")
(define tunnel-target (string-append tunnel-id ".cfargotunnel.com"))
(define tunnel-service "http://192.168.36.236:80")

(define (env! name)
  (define value (getenv name))
  (when (or (not value) (string=? (string-trim value) ""))
    (error 'ensure-cloudflare-domain "missing environment variable: ~a" name))
  value)

(define api-token (env! "CLOUDFLARE_API_TOKEN"))
(define account-id (env! "CLOUDFLARE_ACCOUNT_ID"))

(define (normalized-api-token token)
  (define trimmed (string-trim token))
  (define without-assignment
    (regexp-replace #rx"(?i:^cloudflare_api_token[[:space:]]*=[[:space:]]*)" trimmed ""))
  (define without-header
    (regexp-replace #rx"(?i:^authorization:[[:space:]]*)" without-assignment ""))
  (define without-bearer
    (regexp-replace #rx"(?i:^bearer[[:space:]]+)" (string-trim without-header) ""))
  (define without-quotes
    (string-trim without-bearer "\"'"))
  (regexp-replace* #rx"[[:space:]]+" without-quotes ""))

(define (authorization-header token)
  (define normalized (normalized-api-token token))
  (printf "Cloudflare token normalized length: ~a; token-safe chars: ~a\n"
          (string-length normalized)
          (and (regexp-match? #rx"^[A-Za-z0-9_-]+$" normalized) #t))
  (format "Authorization: Bearer ~a" normalized))

(define (cloudflare-request method path [payload #f])
  (define curl
    (or (find-executable-path "curl")
        (error 'ensure-cloudflare-domain "curl not found")))
  (define body (and payload (jsexpr->string payload)))
  (define command
    (append
     (list (path->string curl)
           "-fsS"
           "--fail-with-body"
           "-X" method
           (string-append "https://api.cloudflare.com" path)
           "-H" (authorization-header api-token)
           "-H" "Content-Type: application/json")
     (if body (list "--data" body) '())))
  (define proc-result (apply process*/ports #f #f #f command))
  (define out (list-ref proc-result 0))
  (define in (list-ref proc-result 1))
  (define err (list-ref proc-result 3))
  (define proc (list-ref proc-result 4))
  (close-output-port in)
  (define response-body (port->string out))
  (define error-body (port->string err))
  (proc 'wait)
  (unless (eq? (proc 'status) 'done-ok)
    (error 'ensure-cloudflare-domain "~a ~a failed\n~a\n~a"
           method path response-body error-body))
  (define parsed
    (if (string=? (string-trim response-body) "")
        (hash)
        (with-input-from-string response-body read-json)))
  (when (eq? (hash-ref parsed 'success #t) #f)
    (error 'ensure-cloudflare-domain "~a ~a failed\n~a" method path response-body))
  parsed)

(define (result-list response)
  (define result (hash-ref response 'result '()))
  (cond
    [(list? result) result]
    [(vector? result) (vector->list result)]
    [else '()]))

(define (zone-id)
  (define response
    (cloudflare-request "GET"
                        (format "/client/v4/zones?name=~a" zone-name)))
  (match (result-list response)
    [(list zone _ ...)
     (hash-ref zone 'id)]
    [_ (error 'ensure-cloudflare-domain "Cloudflare zone not found: ~a" zone-name)]))

(define (dns-records zone-id)
  (result-list
   (cloudflare-request "GET"
                       (format "/client/v4/zones/~a/dns_records?name=~a"
                               zone-id
                               hostname))))

(define (ensure-dns-record! zone-id)
  (define payload
    (hash 'type "CNAME"
          'name hostname
          'content tunnel-target
          'ttl 1
          'proxied #t))
  (match (dns-records zone-id)
    [(list record _ ...)
     (cloudflare-request "PUT"
                         (format "/client/v4/zones/~a/dns_records/~a"
                                 zone-id
                                 (hash-ref record 'id))
                         payload)
     (printf "Updated DNS record: ~a CNAME ~a\n" hostname tunnel-target)]
    ['()
     (cloudflare-request "POST"
                         (format "/client/v4/zones/~a/dns_records" zone-id)
                         payload)
     (printf "Created DNS record: ~a CNAME ~a\n" hostname tunnel-target)]))

(define (tunnel-config-path)
  (format "/client/v4/accounts/~a/cfd_tunnel/~a/configurations"
          account-id
          tunnel-id))

(define (hostname-rule? rule)
  (equal? hostname (hash-ref rule 'hostname #f)))

(define (fallback-rule? rule)
  (not (hash-has-key? rule 'hostname)))

(define (type-rule)
  (hash 'hostname hostname
        'service tunnel-service))

(define (ensure-type-rule ingress)
  (define filtered (filter (lambda (rule) (not (hostname-rule? rule))) ingress))
  (define-values (before after)
    (splitf-at filtered (lambda (rule) (not (fallback-rule? rule)))))
  (append before (list (type-rule)) after))

(define (ensure-tunnel-config!)
  (define current (cloudflare-request "GET" (tunnel-config-path)))
  (define config (hash-ref (hash-ref current 'result) 'config))
  (define ingress (hash-ref config 'ingress))
  (define next-config (hash-set config 'ingress (ensure-type-rule ingress)))
  (define updated
    (cloudflare-request "PUT"
                        (tunnel-config-path)
                        (hash 'config next-config)))
  (printf "Updated tunnel config version ~a for ~a\n"
          (hash-ref (hash-ref updated 'result) 'version)
          hostname))

(module+ main
  (define zid (zone-id))
  (ensure-dns-record! zid)
  (ensure-tunnel-config!))
