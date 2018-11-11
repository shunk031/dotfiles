;;; packages.el --- japanese layer packages file for Spacemacs.
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
;; added to `japanese-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `japanese/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `japanese/pre-init-PACKAGE' and/or
;;   `japanese/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst japanese-packages
  '(
    migemo
    mozc
    mozc-popup
    (mozc-el-extensions :location (recipe :fetcher github
                                          :repo "iRi-E/mozc-el-extensions"))
    pangu-spacing
    )
  "The list of Lisp packages required by the japanese layer.

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

(defun japanese/init-migemo ()
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
      (migemo-init))))

(defun japanese/init-mozc()
  (use-package mozc
    :init
    (progn
      (add-hook 'mozc-mode-hook
                (lambda()
                  (define-key mozc-mode-map (kbd "<zenkaku-hankaku>") 'toggle-input-method)
                  (define-key mozc-mode-map (kbd "M-`") 'toggle-input-method)))
      ;; minibuffer に入った時、IME を OFF にする
      (add-hook 'minibuffer-setup-hook
                (lambda ()
                  ;; isearch の中でなければ input-method を無効にする
                  ;; (他に良い判定方法があれば、変更してください)
                  (unless (memq 'isearch-done kbd-macro-termination-hook)
                    (deactivate-input-method)))))
    :config
    (progn
      (setq default-input-method "japanese-mozc")
      (setq mozc-helper-program-name "mozc_emacs_helper")
      ;; helm でミニバッファの入力時に IME の状態を継承しない
      (setq helm-inherit-input-method nil)
      (advice-add 'helm-select-action
                  :before (lambda (&rest args)
                            (deactivate-input-method))))))

(defun japanese/init-mozc-popup ()
  (use-package mozc-popup
    :config
    ;; 変換候補をポップアップで表示させるようにする
    (setq mozc-candidate-style 'popup)))

(defun japanese/init-mozc-el-extensions ()
  (progn
    (use-package mozc-cursor-color
      :init
      (progn
        (add-hook 'mozc-im-activate-hook (lambda () (setq mozc-mode t)))
        (add-hook 'mozc-im-deactivate-hook (lambda () (setq mozc-mode nil))))
      :config
      ;; カーソルの色の設定
      (setq mozc-cursor-color-alist
            '((direct . "yellow")
              (read-only . "lime green")
              (hiragana . "dark orange")
              (full-katakana . "goldenrod")
              (half-ascii . "dark orchid")
              (full-ascii . "orchid")
              (half-katakana . "dark goldenrod"))))
    (use-package mozc-mode-line-indicator)))

(defun japanese/init-pangu-spacing ()
  (use-package pangu-spacing
    :init
    (progn ;; replacing `chinese-two-byte' by `japanese'
      (setq pangu-spacing-chinese-before-english-regexp
            (rx (group-n 1 (category japanese))
                (group-n 2 (in "a-zA-Z0-9"))))
      (setq pangu-spacing-chinese-after-english-regexp
            (rx (group-n 1 (in "a-zA-Z0-9"))
                (group-n 2 (category japanese))))
      (spacemacs|hide-lighter pangu-spacing-mode)
      ;; Always insert `real' space in text-mode including org-mode.
      (setq pangu-spacing-real-insert-separtor t)
      ;; (global-pangu-spacing-mode 1)
      (add-hook 'text-mode-hook 'pangu-spacing-mode))))

;;; packages.el ends here
