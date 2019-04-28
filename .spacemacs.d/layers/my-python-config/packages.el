;;; packages.el --- my-python-config layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2018 Sylvain Benner & Contributors
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
    ))

(defun my-python-config/post-init-python ()
  (add-hook 'python-mode-hook 'highlight-indentation-current-column-mode)
  (add-to-list 'exec-path "~/.pyenv/shims")
  (setq flycheck-flake8-maximum-line-length 200)

  (setq lsp-pyls-plugins-pycodestyle-max-line-length 200)
  (setq blacken-line-length 200)
  )

;;; packages.el ends here
