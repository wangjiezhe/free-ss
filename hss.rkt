#! /usr/bin/env racket
#lang racket

(require sxml)
(require "utils.rkt")

(define base-url "https://www.hishadowsocks.com/")
(define prefix "hss")

(define query
  (sxpath '(// (section (@ (equal? (id "free")))) div (div 2))))
(define line-tag "p")

(module+ main
  (cli base-url prefix query line-tag))
