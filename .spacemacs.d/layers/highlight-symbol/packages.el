;;; packages.el --- highlight-symbol layer packages file for Spacemacs.
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
;; added to `highlight-symbol-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `highlight-symbol/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `highlight-symbol/pre-init-PACKAGE' and/or
;;   `highlight-symbol/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst highlight-symbol-packages
  '(
    highlight-symbol
    )
  "The list of Lisp packages required by the highlight-symbol layer.

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

(defun highlight-symbol/init-highlight-symbol ()
  (use-package highlight-symbol
    :init
    (progn
      ;; 自動ハイライトするmodeを設定
      (dolist (hook '(
                      ;; プログラミング言語modeに適応
                      prog-mode-hook
                      nxml-mode-hook
                      ))
        (add-hook hook 'highlight-symbol-mode))

      ;; ソースコードにおいてM-p/M-nでシンボル間を移動できるようにする
      (dolist (hook '(
                      ;; プログラミング言語modeに適応
                      prog-mode-hook
                      nxml-mode-hook
                      ))
        (add-hook hook 'highlight-symbol-nav-mode)))

    :config
    (progn
      ;; 1秒後自動ハイライトされるようになる
      (setq highlight-symbol-idle-delay 0.5)
      (setq highlight-symbol-colors '("HotPink1")))))

;;; packages.el ends here
