;;
;; setting for linum-mode.el
;;

;; 背景の色を設定する
;; (custom-set-faces
;;  '(linum ((t (:inherit (shadow default) :background "Gray5")))))

;; (custom-set-faces
;;  '(linum ((t (:inherit (shadow default) :background "#002B36")))))

;; 番号のフォーマットを3桁にしておく
(setq linum-format "%3d ")

(dolist (hook '(
		
		;; c系modeで利用する
		c-mode-common-hook
				
		;; python-modeで利用する
		python-mode-hook
		
		;; R-modeで利用する
		R-mode-hook
		
		;; emacs-lisp-modeで利用する
		emacs-lisp-mode-hook

		;; lisp-modeで利用する
		lisp-mode-hook
		
		;; web-modeで利用する
		web-mode-hook
		
		;; css-modeで利用する
		css-mode-hook
		
		;; gfm-modeで利用する
		gfm-mode-hook
		
		;; arduino-modeで利用する
		arduino-mode-hook
		
		;; shell-script-modeで利用する
		sh-mode-hook
		
		;; markdown-modeで利用する
		markdown-mode-hook
		
		;; octave-modeで利用する
		octave-mode-hook
		
		;; nxml-modeで利用する
		nxml-mode-hook

		;; yatex-modeで利用する
		yatex-mode-hook

		;; graphviz-dot-modeで利用する
		graphviz-dot-mode-hook

		;; generic-modeで利用する
		default-generic-mode-hook
		
		))
  (add-hook hook 'linum-mode))
