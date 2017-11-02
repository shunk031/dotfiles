(el-get-bundle helm)

(use-package helm-config
  :defer t
  :commands (delete-backward-char helm-execute-persistent-action)
  
  :init
  (bind-key "C-h" 'delete-backward-char helm-map)
  (bind-key "C-h" 'delete-backward-char helm-find-files-map)
  (bind-key "TAB" 'helm-execute-persistent-action helm-find-files-map)
  (bind-key "TAB" 'helm-execute-persistent-action helm-read-file-map)
    
  :bind (("M-x" . helm-M-x)
	 ("C-x C-f" . helm-find-files)
	 ("C-x C-r" . helm-recentf)
	 ("M-y" . helm-show-kill-ring)
	 ("C-c i" . helm-imenu)
	 ("C-x b" . helm-for-files)
	 ("C-c s" . helm-tramp))
  
  :config
  (helm-mode 1)
  
  ;; helm-migemo-modeを有効にする
  (helm-migemo-mode 1)
  
  ;; helm-buffers-list のバッファ名の領域が狭いので
  (setq helm-buffer-max-length 50)

  ;; いくつかのhelmコマンドを無効にする
  (add-to-list 'helm-completing-read-handlers-alist '(find-alternate-file . nil))
  
  ;; 候補選択時のディレイを無くす
  (setq helm-exit-idle-delay 0)

  ;; helmミニバッファ内でkill-lineを使えるようにする
  (setq helm-delete-minibuffer-contents-from-point t)
  (defadvice helm-delete-minibuffer-contents (before helm-emulate-kill-line activate)
    "Emulate `kill-line' in helm minibuffer"
    (kill-new (buffer-substring (point) (field-end))))

  (defadvice helm-ff-kill-or-find-buffer-fname (around execute-only-if-exist activate)
    "Execute command only if CANDIDATE exists"
    (when (file-exists-p candidate)
      ad-do-it))
  
  (defadvice helm-ff-transform-fname-for-completion (around my-transform activate)
    "Transform the pattern to reflect my intention"
    (let* ((pattern (ad-get-arg 0))
	   (input-pattern (file-name-nondirectory pattern))
	   (dirname (file-name-directory pattern)))
      (setq input-pattern (replace-regexp-in-string "\\." "\\\\." input-pattern))
      (setq ad-return-value
	    (concat dirname
		    (if (string-match "^\\^" input-pattern)
			;; '^' is a pattern for basename
			;; and not required because the directory name is prepended
			(substring input-pattern 1)
		      (concat ".*" input-pattern))))))
    
  ;; popwinでポップアップさせるときにバッファが二重になるのを防ぐ
  (helm-autoresize-mode 1)
  
  ;; maxとminの値を一緒にすることで
  ;; リサイズせず一定の大きさに表示するようにする
  (setq helm-autoresize-max-height 50)
  (setq helm-autoresize-min-height 50)

  ;; helm-yasnippetを利用できるようにする
  ;; (defun my-yas/prompt (prompt choices &optional display-fn)
  ;;   (let* ((names (loop for choice in choices
  ;; 			collect (or (and display-fn (funcall display-fn choice))
  ;; 				    choice)))
  ;; 	   (selected (helm-other-buffer
  ;; 		      `(((name . ,(format "%s" prompt))
  ;; 			 (candidates . names)
  ;; 			 (action . (("Insert snippet" . (lambda (arg) arg))))))
  ;; 		      "*helm yas/prompt*")))
  ;;     (if selected
  ;; 	  (let ((n (position selected names :test 'equal)))
  ;; 	    (nth n choices))
  ;; 	(signal 'quit "user quit!"))))

  ;; (setq yas-prompt-functions '(my-yas/prompt))
  )
