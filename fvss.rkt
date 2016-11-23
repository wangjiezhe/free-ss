#! /usr/bin/env racket
#lang racket

(require sxml)
(require "utils.rkt")

(define base-url "http://freevpnss.cc/")
(define prefix "fvss")

(define query
  (sxpath '(// div (div 5) div div
               (div (@ (equal? (class "panel-body")))))))
(define line-tag "p")

(module+ main
  (cli base-url prefix query line-tag))
