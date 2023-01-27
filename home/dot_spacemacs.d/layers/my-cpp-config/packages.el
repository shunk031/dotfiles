;;; packages.el --- my-cpp-config layer packages file for Spacemacs.
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
;; added to `my-cpp-config-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `my-cpp-config/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `my-cpp-config/pre-init-PACKAGE' and/or
;;   `my-cpp-config/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:



(defconst my-cpp-config-packages
  '(
    cc-mode
    ))

(defun my-cpp-config/post-init-cc-mode ()
  (use-package cc-mode
    :init
    (add-hook 'c-mode-common-hook 'spacemacs//clang-format-buffer-smart-on-save)
    ))

;;; packages.el ends here
