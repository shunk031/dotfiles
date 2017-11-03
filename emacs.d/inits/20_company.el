(el-get-bundle company)
(el-get-bundle company-statistics)

(use-package company
  :bind
  (("M-i" . company-complete))
  
  :init
  
  (global-company-mode t)
  (add-hook 'after-init-hook 'company-statistics-mode)
  (bind-key "C-n" 'company-select-next company-active-map)
  (bind-key "C-p" 'company-select-previous company-active-map)

  :config
  (setq company-tooltip-limit 20)
  (setq company-idle-delay 0.1)
  (setq company-require-match nil)

  ;; TABで候補を設定
  (define-key company-active-map (kbd "<tab>") 'company-complete-selection)
  
  ;; company-backendsのデフォルトを設定
  (setq company-backends '((company-ispell company-keywords company-files)))
  
  )
