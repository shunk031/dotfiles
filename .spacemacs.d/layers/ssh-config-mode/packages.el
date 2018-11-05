;;; packages.el --- ssh-config-mode layer packages file for Spacemacs.
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
;; added to `ssh-config-mode-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `ssh-config-mode/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `ssh-config-mode/pre-init-PACKAGE' and/or
;;   `ssh-config-mode/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst ssh-config-mode-packages
  '(
    (ssh-config-mode :location (recipe :fetcher github
                                       :repo "jhgorrell/ssh-config-mode-el"
                                       :files ("ssh-config-mode.el" "ssh-config-keywords.txt")))
    )
  "The list of Lisp packages required by the ssh-config-mode layer.

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

(defun ssh-config-mode/init-ssh-config-mode ()
  (use-package ssh-config-mode
    :init
    (add-hook 'ssh-config-mode-hook 'turn-on-font-lock)
    :config
    (progn
      (add-to-list 'auto-mode-alist '("/\\.ssh/config\\'"     . ssh-config-mode))
      (add-to-list 'auto-mode-alist '("/sshd?_config\\'"      . ssh-config-mode))
      (add-to-list 'auto-mode-alist '("/known_hosts\\'"       . ssh-known-hosts-mode))
      (add-to-list 'auto-mode-alist '("/authorized_keys2?\\'" . ssh-authorized-keys-mode)))))

;;; packages.el ends here
