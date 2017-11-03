;;
;; setting for whitespace-mode.el
;;

;; ===================================================================

;; 【参考】Emacs: whitespace-mode like jaspace
;; http://piyolian.blogspot.jp/2011/12/emacs-whitespace-like-jaspace.html

;; ===================================================================

(use-package whitespace
  :defer t
  :config
  (setq whitespace-style
	'(face
	  tabs spaces newline trailing space-before-tab space-after-tab
	  space-mark tab-mark newline-mark))
  
  ;; 全角スペースを表示させる
  (setq whitespace-space-regexp "\\(　+\\)")
  
  (setq whitespace-display-mappings
	'((space-mark   ?\xA0  [?\xA4]  [?_]) ; hard space - currency
	  (space-mark   ?\x8A0 [?\x8A4] [?_]) ; hard space - currency
	  (space-mark   ?\x920 [?\x924] [?_]) ; hard space - currency
	  (space-mark   ?\xE20 [?\xE24] [?_]) ; hard space - currency
	  (space-mark   ?\xF20 [?\xF24] [?_]) ; hard space - currency
	  (space-mark   ?　    [?□]    [?＿]) ; full-width space - square
	  (newline-mark ?\n    [?\xAB ?\n])   ; eol - right quote mark
	  ))
  (setq whitespace-global-modes '(not dired-mode tar-mode)))
