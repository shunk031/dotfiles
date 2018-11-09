(el-get-bundle go-mode)
(use-package go-mode)

(el-get-bundle go-company)
(use-package company-go
  :init
  (add-hook 'go-mode-hook 'company-mode)
  (add-to-list 'company-backends 'company-go)
  
  :config
  (setq company-go-insert-arguments nil))

(el-get-bundle go-eldoc)
(use-package go-eldoc
  :init
  (add-hook 'go-mode-hook 'go-eldoc-setup))

(defun my/gofmt-before-save ()
  "Function to run the GOFMT before each save inside Go mode."
  (set (make-local-variable 'before-save-hook)
       (append before-save-hook (list #'gofmt-before-save))))

(add-hook 'go-mode-hook #'my/gofmt-before-save)

;;; helm-doc
(defvar my/helm-go-source
  '((name . "Helm Go")
    (candidates . go-packages)
    (action . (("Show document" . godoc)
               ("Import package" . my/helm-go-import-add)))))

(defun my/helm-go-import-add (candidate)
  (dolist (package (helm-marked-candidates))
    (go-import-add current-prefix-arg package)))

(defun my/helm-go ()
  (interactive)
  (helm :sources '(my/helm-go-source) :buffer "*helm go*"))

(define-key go-mode-map (kbd "C-c C-d") 'my/helm-go)
