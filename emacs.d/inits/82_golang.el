(el-get-bundle go-mode)
(el-get-bundle go-company)
(el-get-bundle go-eldoc)

;; (use-package company-go
;;   :init
;;   (add-hook 'go-mode-hook (lambda ()
;; 			    (set (make-local-variable 'company-backends) '(company-go))
;; 			    (company-mode)))
;;   )

(use-package go-mode
  :init
  (add-hook 'go-mode-hook (lambda ()
			    (add-hook 'before-save-hook' 'gofmt-before-save)
			    (set (make-local-variable 'company-backends) '(company-go))
			    (company-mode)
			    )))

(use-package go-eldoc
  :init
  (add-hook 'go-mode-hook 'go-eldoc-setup)
  )
