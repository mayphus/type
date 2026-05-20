#lang racket/base

(require "../core/dsl.rkt")

(provide char-action
         symbol-action
         shortcut-action
         keyboard-type-action)

(define (char-action value)
  (object ["character" value]))

(define (symbol-action value)
  (object ["symbol" value]))

(define (shortcut-action value)
  (object ["shortcut" value]))

(define (keyboard-type-action value)
  (object ["keyboardType" value]))
