(add-hook 'emacs-lisp-mode-hook
	  (lambda()
	    (set (make-local-variable 'company-backends) '(company-elisp))))
