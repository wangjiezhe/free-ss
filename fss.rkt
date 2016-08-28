#! /usr/bin/env racket
#lang racket

(require sxml)
(require "utils.rkt")

(define base-url "http://freeshadowsocks.cf/")
(define prefix "fss")

(define query
  (sxpath '(html body (div 1) (div 2) div)))
(define line-tag "h4")

(module+ main
  (cli base-url prefix query line-tag))
