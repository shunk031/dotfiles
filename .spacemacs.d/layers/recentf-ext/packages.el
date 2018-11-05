;;; packages.el --- recentf-ext layer packages file for Spacemacs.
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
;; added to `recentf-ext-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `recentf-ext/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `recentf-ext/pre-init-PACKAGE' and/or
;;   `recentf-ext/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst recentf-ext-packages
  '(
    recentf-ext
    )
  "The list of Lisp packages required by the recentf-ext layer.

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

(defun recentf-ext/init-recentf-ext ()
  (use-package recentf-ext
    :defer t
    :commands (recentf-open-files)
    :init
    (add-hook 'after-init-hook
                (lambda ()
                  (recentf-open-files)))
    :config
    (progn
      (defmacro with-suppressed-message (&rest body)
        "Suppress new messages temporarily in the echo area and the `*Messages*' buffer while BODY is evaluated."
        (declare (indent 0))
        (let ((message-log-max nil))
          `(with-temp-message (or (current-message) "") ,@body)))

      (defadvice recentf-open-files (before recentf-abbrev-file-name-adv activate)
        (recentf-cleanup)
        (let ((directory-abbrev-alist `((,(concat "\\`" (getenv "HOME")) . "~"))))
          (setq recentf-list (mapcar #'(lambda (x) (abbreviate-file-name x)) recentf-list))))

      (defadvice recentf-open-files (after recentf-set-overlay-directory-adv activate)
        (set-buffer "*Open Recent*")
        (save-excursion
          (while (re-search-forward "\\(^  \\[[0-9]\\] \\|^  \\)\\(.*/\\)$" nil t nil)
            (overlay-put (make-overlay (match-beginning 2) (match-end 2))
                         'face `((:foreground ,"#F1266F"))))))

      (setq recentf-max-saved-items 100)
      (setq recentf-save-file "~/.dotfiles/.spacemacs.d/recentf")
      (setq recentf-exclude '("recentf"))
      (setq recentf-auto-cleanup 'never)
      (recentf-mode t))
    )
  )

;;; packages.el ends here
