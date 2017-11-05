(el-get-bundle go-mode)
(el-get-bundle nsf/gocode)

(use-package company-go
  :init
  (add-hook 'go-mode-hook (lambda ()
			    (set (make-local-variable 'company-backends) '(company-go))
			    (company-mode)))
  )
