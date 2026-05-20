#lang racket/base

;;; Stable public facade for Kubernetes workflow helpers.

(require "workflow/k8s.rkt")

(provide (all-from-out "workflow/k8s.rkt"))

(module+ main
  (render-deploy-artifacts!))
