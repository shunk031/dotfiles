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
    avy-migemo
    ))

(defun migemo/init-migemo ()
  (use-package migemo
    :config
    (progn
      (setq migemo-command "cmigemo")
      (setq migemo-options '("-q" "--emacs" "\a"))
      (cond
       ((eq system-type 'darwin)
        (setq migemo-dictionary "/usr/local/share/migemo/utf-8/migemo-dict"))
       ((eq system-type 'gnu/linux)
        (setq migemo-dictionary "/usr/share/cmigemo/utf-8/migemo-dict")))
      (setq completion-ignore-case t)
      (setq migemo-user-dictionary nil)
      (setq migemo-regex-dictionary nil)
      (setq migemo-coding-system 'utf-8-unix)
      (migemo-init)
      )
    )
  )

(defun migemo/init-avy-migemo ()
  (use-package avy-migemo
    :after swiper
    :config
    (require 'avy-migemo-e.g.swiper))
  )

;;; packages.el ends here
