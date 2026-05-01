;;; packages.el --- migemo layer packages file for Spacemacs.
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
;; added to `migemo-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `migemo/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `migemo/pre-init-PACKAGE' and/or
;;   `migemo/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst migemo-packages
  '(
    migemo
    (avy-migemo :location (recipe :fetcher github
                                  :repo "tam17aki/avy-migemo"))
    ))

(defun migemo/init-migemo ()
  (use-package migemo
    :custom
    (migemo-command (executable-find "cmigemo"))
    (migemo-options '("-q" "--emacs"))
    (migemo-user-dictionary nil)
    (migemo-regex-dictionary nil)
    (migemo-coding-system 'utf-8-unix)
    (migemo-dictionary "/usr/share/cmigemo/utf-8/migemo-dict")
    :config
    (when (eq system-type 'darwin)
      (setq migemo-dictionary
            (concat
             (file-name-as-directory
              (shell-command-to-string "printf %s \"$(brew --prefix)\""))
             "share/migemo/utf-8/migemo-dict")))
    (migemo-init)))

(defun migemo/init-avy-migemo ()
  (use-package avy-migemo
    :config
    (progn
      (avy-migemo-mode 1)
      )
    ))

;;; packages.el ends here
