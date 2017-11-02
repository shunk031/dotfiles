(el-get-bundle highlight-symbol)
(use-package highlight-symbol
  :init
  ;; 自動ハイライトするmodeを設定
  (dolist (hook '(
		  
		  ;; プログラミング言語modeに適応
		  prog-mode-hook
		  
		  nxml-mode-hook
		  
		  ))
    (add-hook hook 'highlight-symbol-mode))
  
  ;; ソースコードにおいてM-p/M-nでシンボル間を移動できるようにする
  (dolist (hook '(
		  
		  ;; プログラミング言語modeに適応
		  prog-mode-hook
		  
		  nxml-mode-hook
		  
		  ))
    (add-hook hook 'highlight-symbol-nav-mode))
  
  :bind ("C-c r" . highlight-symbol-query-replace) ;; シンボル置換できるようにする
  
  :config
  ;; 1秒後自動ハイライトされるようになる
  (setq highlight-symbol-idle-delay 0.5))
