#lang racket

(provide
 (contract-out
  [get-accounts (-> string? sxpath/c string? (listof dict?))]
  [dump-accounts (-> (listof dict?) string? any)]
  [cli (-> string? string? sxpath/c string? any)]))

(require net/url
         json)
(require html-parsing
         sxml)

(define *conf-file-template* "/etc/shadowsocks/~a-~a.json")

(define sxpath/c
  (-> list? list?))

; (-> String SXML)
(define (get url-string)
  (call/input-url
    (string->url url-string)
    (curry get-pure-port #:redirections 5)
    html->xexp))

; (-> SXML String String)
(define (matcher line line-tag)
  (match line
    [`(,line-tag ,(? string? a)) a]
    [`(,line-tag ,(? string? a) (font ,_ ,(? string? b))) (string-append a b)]
    [`(,line-tag (font ,_ ,(? string? b))) b]
    [_ #f]))

; (-> String (Listof String))
(define (spliter text)
  (regexp-split #rx":|：" text))

; (-> String String)
(define (convert-status status)
  (if (string=? status "正常")
      #t
      #f))

; (-> List Dict)
(define (list->alist conf-list)
  (filter identity
          (for/list ([c conf-list]
                     #:unless (null? (cdr c)))
            (let ([k (first c)]
                  [v (second c)])
              (match k
                [(regexp #rx".*服务器地址") `(server . ,v)]
                [(regexp #rx"端口") `(server_port . ,v)]
                [(regexp #rx".*密码") `(password . ,v)]
                [(regexp #rx"加密方式") `(method . ,v)]
                [(regexp #rx"状态") `(status . ,(convert-status v))]
                [_ #f])))))

; (-> Dict Hash)
(define (alist->hash alist)
  (make-hasheq (dict-remove alist 'status)))

;(-> SXML String (Listof Dict))
(define (parser content line-tag)
  (list->alist
   (map spliter
        (filter identity
                (map (curryr matcher line-tag)
                     ((sxpath line-tag) content))))))

; (-> Dict String)
(define (account-name acc)
  (first (string-split (dict-ref acc 'server) ".")))

; (-> (U Null String) List List)
(define (proxy->list proxy orig-list)
  (cond
    [(null? proxy) orig-list]
    [else
     (define plist (regexp-split #rx":" proxy))
     `(,@orig-list ("http" ,(first plist) ,(string->number (second plist))))]))

; (-> String SXPath SXPath (Listof Dict))
(define (get-accounts aurl query line-tag)
  (define doc (get aurl))
  (define content-list (query doc))
  (for/list ([content content-list])
    (parser content line-tag)))

; (-> Dict String Void)
(define (dump-account acc prefix)
  (call-with-output-file
      (format *conf-file-template* prefix (account-name acc))
    (λ (out)
      (write-json (alist->hash acc) out)
      (newline out))
    #:exists 'truncate/replace))

; (-> (Listof Dict) String Void)
(define (dump-accounts acc-list prefix)
  (for ([acc acc-list]
        ;; #:when (or (not (dict-has-key? acc 'status))
        ;;            (dict-ref acc 'status))
        )
    ; (displayln acc)
    (dump-account acc prefix)))

; (-> String String SXPath String Void)
(define (cli base-url prefix query line-tag)
  (define dump (make-parameter #f))
  (define use-proxy (make-parameter '()))
  (command-line
   #:once-each
   [("-d" "--dump") "Dump to default configuration files"
                    (dump #t)]
   #:multi
   [("-x" "--proxy")
    proxy
    "Use proxy [hostname:port] (only http proxy is supported now)"
    (use-proxy (proxy->list proxy (use-proxy)))]
   #:usage-help "Fetch free shadowsocks accounts"
   #:args ()
   (define acc-list
     (parameterize ([current-proxy-servers (use-proxy)])
       (get-accounts base-url query line-tag)))
   (for-each displayln acc-list)
   (when (dump)
     (dump-accounts acc-list prefix))))
