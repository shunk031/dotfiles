;;; packages.el --- my-python-config layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2017 Sylvain Benner & Contributors
;;
;; Author: Shunsuke KITADA <shunk031@DeepLearningIsAllYouNeed.local>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `my-python-config-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `my-python-config/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `my-python-config/pre-init-PACKAGE' and/or
;;   `my-python-config/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst my-python-config-packages
  '(
    (python :location built-in)
    flycheck-mypy
    ;; lsp-mode
    ;; lsp-ui
    ;; company-lsp
    )
  "The list of Lisp packages required by the my-python-config layer.

Each entry is either:

1. A symbol, which is interpreted as a package to be installed, or

2. A list of the form (PACKAGE KEYS...), where PACKAGE is the
    name of the package to be installed or loaded, and KEYS are
    any number of keyword-value-pairs.

    The following keys are accepted:

    - :excluded (t or nil): Prevent the package from being loaded
      if value is non-nil

    - :location: Specify a custom installation location.
      The following values are legal:

      - The symbol `elpa' (default) means PACKAGE will be
        installed using the Emacs package manager.

      - The symbol `local' directs Spacemacs to load the file at
        `./local/PACKAGE/PACKAGE.el'

      - A list beginning with the symbol `recipe' is a melpa
        recipe.  See: https://github.com/milkypostman/melpa#recipe-format")

(defun my-python-config/post-init-python ()
  (use-package python
    :defer t
    :init
    (progn
      (add-hook 'python-mode-hook 'py-autopep8-enable-on-save)
      (add-hook 'python-mode-hook 'highlight-indentation-current-column-mode)
      (add-hook 'python-mode-hook 'pangu-spacing-mode)
      )
    :config
    (progn
      (add-to-list 'exec-path "~/.pyenv/shims")
      (setq py-autopep8-options '("--max-line-length=200"))
      (setq flycheck-flake8-maximum-line-length 200)
      (setq py-isort-options '("-m=3")))))

(defun my-python-config/init-flycheck-mypy ()
  (use-package flycheck-mypy
    :init
    (progn
      ;; (set-variable 'flycheck-python-module-args '("--ignore-missing-imports"))
      ;; (flycheck-add-next-checker 'python-flake8 'python-mypy t)
      )
    )
  )

;; (defun my-python-config/init-lsp-mode ()
;;   (use-package lsp-mode
;;     :commands (lsp)
;;     :init
;;     (add-hook 'python-mode-hook #'lsp)))

;; (defun my-python-confi/init-lsp-ui ()
;;   (use-package lsp-ui
;;     :commands (lsp-ui-mode)
;;     :init
;;     (add-hook 'lsp-mode-hook 'lsp-ui-mode)
;;     :config
;;     (setq lsp-ui-sideline-ignore-duplicate t)))

;; (defun my-python-config/init-company-lsp ()
;;   (use-package company-lsp
;;     :config
;;     (push 'company-lsp company-backends)))

;;; packages.el ends here
