;;
;; setting for C/C++ development environment
;;

;; ===================================================================

;; 【参考】Emacs における C, C++ 系モードのインデント設定
;; http://yohshiy.blog.fc2.com/blog-entry-264.html

;; ===================================================================

;;; VisualStudioのスタイルを使う

;; BSDスタイルの設定では足りない設定を補う
(el-get-bundle vs-set-c-style
  :url "https://raw.githubusercontent.com/shunk031/myoshida-rp/master/elisp/vs-set-c-style.el")

(use-package vs-set-c-style
  :init
  (add-hook 'c-mode-hook 'vs-set-c-style)
  (add-hook 'c++-mode-hook 'vs-set-c-style)
  )

;; C++-modeでのFlycheckをC++11を利用する
(add-hook 'c++-mode-hook
	  (lambda ()
	    (setq flycheck-gcc-language-standard "c++11")))

;; C/C++のスタイルをBSDに設定
(setq c-default-style '((c-mode . "bsd")
			(c++-mode . "bsd")
			(java-mode . "java")
			(awk-mode . "awk")
			(other . "gnu")))

;; 改行位置を変更
(setq c-hanging-braces-alist
      '((defun-open before after)
	(defun-close before after)
	(class-open before after)
	(class-close before after)
	(inline-open before after)
	(inline-close before after)
	(block-open before after)
	(block-close . c-snug-do-while)
	(statement-cont before after)
	(substatement-open before after)
	(statement-case-open before after)
	(brace-list-open before after)
	(brace-list-close before after)
	(brace-list-intro before after)
	(brace-entry-open before after)
	(extern-lang-open before after)
	(extern-lang-close before after)
	(namespace-open before after)
	(namespace-close before after)
	(module-open before after)
	(module-close before after)
	(composition-open before after)
	(composition-close before after)
	(inexpr-class-open before after)
	(inexpr-class-close before after)
	(arglist-cont-nonempty before after)))
