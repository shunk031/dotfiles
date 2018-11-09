;;
;; setting for which-key.el
;; https://github.com/justbur/emacs-which-key

;; ===================================================================

;; 【参考】次のキー操作をよりわかりやすく教えてくれるぞ！
;; http://rubikitch.com/2015/09/14/which-key/

;; ===================================================================

(el-get-bundle justbur/emacs-which-key)

(use-package which-key
  ;; :disabled t
  :config
  
  ;; which-key発動までの時間を設定
  (setq which-key-idle-delay 1.0) 
  
  ;; 右端に表示するようにする
  (which-key-setup-side-window-right)

  (setq which-key-key-replacement-alist
  	'(("<\\([[:alnum:]-]+\\)>" . "\\1")
  	  ("left"                . "◀")
  	  ("right"               . "▶")
  	  ("up"                  . "▲")
  	  ("down"                . "▼")
  	  ("delete"              . "DLT") ; delete key
  	  ("\\`DEL\\'"             . "BS") ; backspace key
  	  ("next"                . "PgDn")
  	  ("prior"               . "PgUp")))
  
  (which-key-mode))
