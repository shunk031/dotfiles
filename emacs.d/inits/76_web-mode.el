;;
;; setting for web-mode.el
;; https://github.com/fxbois/web-mode

;; ===================================================================

;; 【参考】html5でも正しくインデントしてくれるweb-modeを導入してみた
;; http://yanmoo.blogspot.jp/2013/06/html5web-mode.html

;; ===================================================================

(el-get-bundle web-mode)

(use-package web-mode
  
  :mode (("\\.html?\\'" . web-mode)
	 ("\\.xhtml\\'" . web-mode)
	 ("\\.shtml\\'" . web-mode)
	 ("\\.tpl\\'" . web-mode)
	 ("\\.jsp\\'" . web-mode)
	 ("\\.blade\\.php\\'" . web-mode))
  
  :config

  (defun my-web-mode-hook ()
    
    "Hooks for Web mode."
    
    ;; web-modeの設定
    (setq web-mode-markup-indent-offset 2) ;; html indent
    (setq web-mode-css-indent-offset 2)    ;; css indent
    (setq web-mode-code-indent-offset 2)   ;; script indent(js,php,etc..)
    
    ;; コメントスタイルの指定
    (setq web-mode-comment-style 2))
  (add-hook 'web-mode-hook  'my-web-mode-hook)
  
  ;;blade記法/PHP記法をハイライトするようにする
  (setq web-mode-engines-alist
	'(("php" . "\\.html\\'")
	  ("blade"  . "\\.blade\\.")))
  
  ;; C-c ; で コメント、アンコメントする
  (bind-key "C-c ;" 'web-mode-comment-or-uncomment web-mode-map)

  ;; (custom-set-faces
  ;;  '(web-mode-doctype-face
  ;;    ((t (:foreground "#82AE46"))))                          ; doctype
  ;;  '(web-mode-html-tag-face
  ;;    ((t (:foreground "#E6B422" :weight bold))))             ; 要素名
  ;;  '(web-mode-html-attr-name-face
  ;;    ((t (:foreground "#C97586"))))                          ; 属性名など
  ;;  '(web-mode-html-attr-value-face
  ;;    ((t (:foreground "#82AE46"))))                          ; 属性値
  ;;  '(web-mode-comment-face
  ;;    ((t (:foreground "#D9333F"))))                          ; コメント
  ;;  '(web-mode-server-comment-face
  ;;    ((t (:foreground "#D9333F"))))                          ; コメント
  ;;  '(web-mode-css-rule-face
  ;;    ((t (:foreground "#A0D8EF"))))                          ; cssのタグ
  ;;  '(web-mode-css-pseudo-class-face
  ;;    ((t (:foreground "#FF7F00"))))                          ; css 疑似クラス
  ;;  '(web-mode-css-at-rule-face
  ;;    ((t (:foreground "#FF7F00"))))                          ; cssのタグ
  ;;  )
  
  )
