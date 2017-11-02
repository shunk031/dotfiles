(el-get-bundle flyspell)

(use-package flyspell
  
  :config
  (mapc
   (lambda (hook)
     (add-hook hook 'flyspell-prog-mode))
   '(
     ;; ここに書いたモードではコメント領域のところだけ
     ;; flyspell-mode が有効になる
     c-mode-common-hook                 
     emacs-lisp-mode-hook
     python-mode-hook
     ))
  (mapc
   (lambda (hook)
     (add-hook hook
	       '(lambda () (flyspell-mode 1))))
   '(
     ;; ここに書いたモードでは
     ;; flyspell-mode が有効になる
     yatex-mode-hook     
     gfm-mode-hook
     markdown-mode-hook
     ))
  )
