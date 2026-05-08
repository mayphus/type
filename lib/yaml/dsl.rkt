#lang racket/base

(require "yaml.rkt")

(provide kv
         mapping
         sequence
         bundle
         yaml-file)

(define (yaml-file path document)
  (hash path (yaml->string document)))

(define (bundle . file-groups)
  (for/fold ([merged (hash)]) ([group (in-list file-groups)])
    (for/fold ([acc merged]) ([(path content) (in-hash group)])
      (hash-set acc path content))))
