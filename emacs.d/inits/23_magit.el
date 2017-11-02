(el-get-bundle magit)
(use-package magit
  ;; :defer t
  
  :bind ("C-x m" . magit-status)
  
  :config
  
  ;; ステージしてないファイルが存在する場合は再びmagit-statusバッファを開くようにする
  (defadvice with-editor-finish (around Y/go-back-to-magit-status activate)
    "Go back ‘magit-status’ if there are other un-staged things."
    (let ((dir default-directory))
      ad-do-it
      (when (magit-anything-unstaged-p)
	(magit-status-internal dir))))
  
  ;; magit-commit時にdiffが開かないようにする
  ;; C-c C-dすればdiffを見ることができる
  (remove-hook 'server-switch-hook 'magit-commit-diff))
  
