;;; packages.el --- electric-operator layer packages file for Spacemacs.
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
;; added to `electric-operator-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `electric-operator/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `electric-operator/pre-init-PACKAGE' and/or
;;   `electric-operator/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst electric-operator-packages
  '(
    electric-operator
    )
  "The list of Lisp packages required by the electric-operator layer.

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

(defun electric-operator/init-electric-operator ()
  (use-package electrc-operator
    :commands (electric-operator-mode)
    :init
    (progn
      (spacemacs|diminish electric-operator-mode "" "")
      (dolist (hook '(
                    ;;c系modeで利用する
                    c-mode-common-hook
                    ;; python-modeで利用する
                    python-mode-hook
                    ;; ess-modeで利用する
                    ess-mode-hook
                    ;; arduino-modeで利用する
                    arduino-mode-hook
                    ;; perl-modeで利用する
                    perl-mode-hook
                    ))
      (add-hook hook #'electric-operator-mode)))
    :config
    ;; ジェネリクス型を利用する際に無駄なスペースが入ってしまうために
    ;; java-modeでは"<"と">"において動作しないようにした
    (electric-operator-add-rules-for-mode
     'java-mode
     (cons "<" nil)
     (cons ">" nil))

    (electric-operator-add-rules-for-mode
     'php-mode
     (cons "/" nil)
     (cons "<" nil)
     (cons ">" nil)
     (cons "++" "++")
     (cons "//" "// ")
     (cons "." nil)
     (cons "->" "->")
     (cons "=>" " => "))

    ;; arduino-modeにelectric-operator-prog-mode-rulesを適応
    (apply #'electric-operator-add-rules-for-mode 'arduino-mode
           electric-operator-prog-mode-rules)))

;;; packages.el ends here
