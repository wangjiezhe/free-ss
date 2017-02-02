#! /usr/bin/env racket
#lang racket

(require sxml)
(require "utils.rkt")

(define base-url "http://iss.pm/")
(define prefix "iss")

(define query
  (sxpath '(// (section (@ (equal? (id "free")))) div (div 2) div)))
(define line-tag "h4")

(module+ main
  (cli base-url prefix query line-tag))
