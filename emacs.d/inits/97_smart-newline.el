(el-get-bundle smart-newline)
(use-package smart-newline
  :init
  ;; 個別にモードごとに設定をする
  (dolist
      (hook
       '(

	 ;; ess-modeで利用するようにする
	 ess-mode-hook

	 ;; markdown-modeで利用する
	 markdown-mode-hook
	 
	 ;; gfm-modeで利用するようにする
	 gfm-mode-hook
	 
	 ))
    (add-hook hook
	      (lambda ()
		(smart-newline-mode 1)))))
