;;; packages.el --- config layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2017 Sylvain Benner & Contributors
;;
;; Author: Shunsuke KITADA <shunk031@OguraYuiMacbook.local>
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
;; added to `config-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `config/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `config/pre-init-PACKAGE' and/or
;;   `config/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst config-packages
  '(
    (basic-config :location local)
    (company-config :location local)
    (google-translate-config :location local)
    (helm-config :location local)
    (ispell-config :location local)
    (python-config :location local)
    (popwin-config :location local)
    (undo-tree-config :location local)
    (yasnippet-config :location local)
    )
  "The list of Lisp packages required by the config layer.

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

(defun config/init-basic-config ()
  (use-package basic-config))

(defun config/init-company-config ()
  (use-package company-config
    :after (company)))

(defun config/init-google-translate-config ()
  (use-package google-translate-config))

(defun config/init-helm-config ()
  (use-package helm-config
    :after (helm)))

(defun config/init-ispell-config ()
  (use-package ispell-config))

(defun config/init-popwin-config ()
  (use-package popwin-config
    :after (popwin)))

(defun config/init-python-config ()
  (use-package python-config
    :after (python)))

(defun config/init-undo-tree-config ()
  (use-package undo-tree-config
    :after (undo-tree)))

(defun config/yasnippet-config ()
  (use-package yasnippet-config
    :after(yasnippet)))

;;; packages.el ends here
