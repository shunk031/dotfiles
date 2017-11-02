(el-get-bundle flycheck)
(use-package flycheck
  
  :init
  (add-hook 'after-init-hook #'global-flycheck-mode)
  
  :config
  (setq-default flycheck-disabled-checkers '(emacs-lisp-checkdoc)))
