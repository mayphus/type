#lang racket/base

(require racket/file
         racket/runtime-path
         racket/string
         "../lib/yaml/yaml.rkt")

(provide k8s-documents
         dockerfile-text
         render-k8s-directory!
         render-dockerfile!
         check-k8s-directory!
         check-dockerfile!
         render-k8s!
         check-k8s!
         render-deploy-artifacts!
         check-deploy-artifacts!)

(define-runtime-path dockerfile-path "../Dockerfile")

(define app-name "input-foundry")
(define namespace-name "input-foundry")
(define image-name "ghcr.io/mayphus/input-foundry")
(define http-port 80)
(define container-port 8080)
(define node-port 32080)
(define hosts '("type.mayphus.org" "rime.mayphus.org" "rime-config.mayphus.org"))

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
        (kv "type" "NodePort")
        (kv "selector" (label-map))
        (kv "ports"
            (sequence
             (mapping
              (kv "name" "http")
              (kv "port" http-port)
              (kv "targetPort" "http")
              (kv "nodePort" node-port))))))))

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

(define (render-path dir name)
  (build-path dir name))

(define dockerfile-packages
  '("ca-certificates"
    "fonts-noto-cjk"
    "libgdk-pixbuf-2.0-0"
    "libgdk-pixbuf-xlib-2.0-0"
    "libglib2.0-0"
    "libgtk2.0-0"
    "libjpeg62-turbo"
    "libpangocairo-1.0-0"
    "libpng16-16"
    "librsvg2-bin"
    "racket"
    "zip"))

(define dockerfile-text
  (string-append
   "FROM docker.io/debian:bookworm-slim\n"
   "\n"
   "RUN apt-get update \\\n"
   " && apt-get install -y --no-install-recommends \\\n"
   (string-join
    (for/list ([package (in-list dockerfile-packages)])
      (format "    ~a ~a" package "\\"))
    "\n")
   "\n && rm -rf /var/lib/apt/lists/*\n"
   "\n"
   "WORKDIR /app\n"
   "COPY . .\n"
   "\n"
   "RUN useradd -r -s /sbin/nologin rime \\\n"
   " && chown -R rime /app\n"
   "\n"
   "USER rime\n"
   "\n"
   "EXPOSE 8080\n"
   "\n"
   "CMD [\"racket\", \"main.rkt\", \"serve\"]\n"))

(define (render-k8s-directory! dir)
  (make-directory* dir)
  (for ([entry (in-list k8s-documents)])
    (call-with-output-file (render-path dir (car entry))
      #:exists 'replace
      (lambda (out)
        (display (yaml->string (cdr entry)) out)))))

(define (render-dockerfile!)
  (call-with-output-file dockerfile-path
    #:exists 'replace
    (lambda (out)
      (display dockerfile-text out))))

(define (check-k8s-directory! dir)
  (for ([entry (in-list k8s-documents)])
    (define path (render-path dir (car entry)))
    (define expected (yaml->string (cdr entry)))
    (define actual
      (and (file-exists? path)
           (file->string path)))
    (unless (equal? actual expected)
      (error 'check-k8s!
             "generated Kubernetes manifest is stale: ~a"
             (path->string path)))))

(define (make-k8s-temp-dir!)
  (make-temporary-file "input-foundry-k8s-~a" 'directory))

(define (render-k8s!)
  (define dir (make-k8s-temp-dir!))
  (render-k8s-directory! dir)
  dir)

(define (check-k8s!)
  (define dir (make-k8s-temp-dir!))
  (dynamic-wind
    void
    (lambda ()
      (render-k8s-directory! dir)
      (check-k8s-directory! dir))
    (lambda ()
      (delete-directory/files dir #:must-exist? #f))))

(define (check-dockerfile!)
  (define actual
    (and (file-exists? dockerfile-path)
         (file->string dockerfile-path)))
  (unless (equal? actual dockerfile-text)
    (error 'check-dockerfile!
           "generated Dockerfile is stale: ~a"
           (path->string dockerfile-path))))

(define (render-deploy-artifacts!)
  (render-dockerfile!)
  (render-k8s!))

(define (check-deploy-artifacts!)
  (check-k8s!)
  (check-dockerfile!))

(module+ main
  (render-deploy-artifacts!))
