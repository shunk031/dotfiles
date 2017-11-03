;;
;; setting for adaptive-wrap.el
;; https://github.com/emacsmirror/adaptive-wrap

;; ===================================================================

;; 【参考】Emacsの折り返しの挙動
;; http://alainmathematics.blogspot.jp/2013/07/emacs.html

;; ===================================================================

(el-get-bundle adaptive-wrap)

(use-package adaptive-wrap
    
  :init
  (dolist
      (hook '(
	      
	      ;; c系modeで利用する
	      c-mode-common-hook
	      
	      ;; python-modeで利用する
	      python-mode-hook
	      
	      ;; web-modeで利用する
	      web-mode-hook

	      ;; emacs-lisp-modeで利用する
	      emacs-lisp-mode-hook

	      ;; lisp^modeで利用する
	      lisp-mode-hook

	      ;; graphviz-dot-modeで利用する
	      graphviz-dot-mode-hook

	      ;; gfm-modeで利用する
	      gfm-mode-hook

	      ;; yatex-modeで利用する
	      yatex-mode-hook
	      
	      ))
    (add-hook hook 'adaptive-wrap-prefix-mode)))
