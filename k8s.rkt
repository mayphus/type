#lang racket/base

(require racket/file
         racket/runtime-path
         racket/string
         "lib/yaml/yaml.rkt")

(provide k8s-documents
         render-k8s!
         check-k8s!)

(define-runtime-path k8s-dir "k8s")

(define app-name "rime-config")
(define namespace-name "rime-config")
(define image-name "ghcr.io/mayphus/rime-config")
(define http-port 80)
(define container-port 8080)
(define hosts '("rime.mayphus.org" "rime-config.mayphus.org"))

(define (label-map)
  (mapping (kv "app" app-name)))

(define (metadata [extra '()])
  (apply mapping
         (append
          (list (kv "name" app-name)
                (kv "namespace" namespace-name))
          extra)))

(define namespace-doc
  (mapping
   (kv "apiVersion" "v1")
   (kv "kind" "Namespace")
   (kv "metadata"
       (mapping
        (kv "name" namespace-name)))))

(define (env-var name value)
  (mapping
   (kv "name" name)
   (kv "value" value)))

(define (http-probe initial-delay period)
  (mapping
   (kv "httpGet"
       (mapping
        (kv "path" "/metadata")
        (kv "port" "http")))
   (kv "initialDelaySeconds" initial-delay)
   (kv "periodSeconds" period)))

(define app-container
  (mapping
   (kv "name" "app")
   (kv "image" (string-append image-name ":latest"))
   (kv "imagePullPolicy" "Always")
   (kv "env"
       (sequence
        (env-var "PORT" (number->string container-port))
        (env-var "LISTEN_IP" "0.0.0.0")))
   (kv "ports"
       (sequence
        (mapping
         (kv "containerPort" container-port)
         (kv "name" "http"))))
   (kv "readinessProbe" (http-probe 3 10))
   (kv "livenessProbe" (http-probe 10 20))
   (kv "resources"
       (mapping
        (kv "requests"
            (mapping
             (kv "cpu" "100m")
             (kv "memory" "256Mi")))
        (kv "limits"
            (mapping
             (kv "cpu" "1")
             (kv "memory" "1Gi")))))))

(define pod-spec
  (mapping
   (kv "imagePullSecrets"
       (sequence
        (mapping
         (kv "name" "ghcr-pull"))))
   (kv "containers" (sequence app-container))))

(define deployment-doc
  (mapping
   (kv "apiVersion" "apps/v1")
   (kv "kind" "Deployment")
   (kv "metadata"
       (metadata
        (list (kv "labels" (label-map)))))
   (kv "spec"
       (mapping
        (kv "replicas" 1)
        (kv "revisionHistoryLimit" 2)
        (kv "selector"
            (mapping
             (kv "matchLabels" (label-map))))
        (kv "template"
            (mapping
             (kv "metadata"
                 (mapping
                  (kv "labels" (label-map))))
             (kv "spec" pod-spec)))))))

(define service-doc
  (mapping
   (kv "apiVersion" "v1")
   (kv "kind" "Service")
   (kv "metadata" (metadata))
   (kv "spec"
       (mapping
        (kv "selector" (label-map))
        (kv "ports"
            (sequence
             (mapping
              (kv "name" "http")
              (kv "port" http-port)
              (kv "targetPort" "http"))))))))

(define (host-tls host)
  (mapping
   (kv "hosts" (sequence host))
   (kv "secretName" (string-append (string-replace host "." "-") "-tls"))))

(define (host-rule host)
  (mapping
   (kv "host" host)
   (kv "http"
       (mapping
        (kv "paths"
            (sequence
             (mapping
              (kv "path" "/")
              (kv "pathType" "Prefix")
              (kv "backend"
                  (mapping
                   (kv "service"
                       (mapping
                        (kv "name" app-name)
                        (kv "port"
                            (mapping
                             (kv "number" http-port))))))))))))))

(define ingress-doc
  (mapping
   (kv "apiVersion" "networking.k8s.io/v1")
   (kv "kind" "Ingress")
   (kv "metadata"
       (metadata
        (list (kv "annotations"
                  (mapping
                   (kv "cert-manager.io/cluster-issuer" "letsencrypt"))))))
   (kv "spec"
       (mapping
        (kv "tls" (apply sequence (map host-tls hosts)))
        (kv "rules" (apply sequence (map host-rule hosts)))))))

(define kustomization-doc
  (mapping
   (kv "apiVersion" "kustomize.config.k8s.io/v1beta1")
   (kv "kind" "Kustomization")
   (kv "namespace" namespace-name)
   (kv "resources"
       (sequence
        "namespace.yaml"
        "deployment.yaml"
        "service.yaml"
        "ingress.yaml"))
   (kv "images"
       (sequence
        (mapping
         (kv "name" image-name)
         (kv "newTag" "latest"))))))

(define k8s-documents
  (list (cons "namespace.yaml" namespace-doc)
        (cons "deployment.yaml" deployment-doc)
        (cons "service.yaml" service-doc)
        (cons "ingress.yaml" ingress-doc)
        (cons "kustomization.yaml" kustomization-doc)))

(define (render-path name)
  (build-path k8s-dir name))

(define (render-k8s!)
  (make-directory* k8s-dir)
  (for ([entry (in-list k8s-documents)])
    (call-with-output-file (render-path (car entry))
      #:exists 'replace
      (lambda (out)
        (display (yaml->string (cdr entry)) out)))))

(define (check-k8s!)
  (for ([entry (in-list k8s-documents)])
    (define path (render-path (car entry)))
    (define expected (yaml->string (cdr entry)))
    (define actual
      (and (file-exists? path)
           (file->string path)))
    (unless (equal? actual expected)
      (error 'check-k8s!
             "generated Kubernetes manifest is stale: ~a"
             (path->string path)))))

(module+ main
  (render-k8s!))
