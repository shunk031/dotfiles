;;; packages.el --- mozc layer packages file for Spacemacs.
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
;; added to `mozc-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `mozc/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `mozc/pre-init-PACKAGE' and/or
;;   `mozc/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst mozc-packages
  '(
    mozc
    mozc-popup
    (mozc-el-extensions :location (recipe :fetcher github
                                          :repo "iRi-E/mozc-el-extensions"))
    ))

(defun mozc/init-mozc()
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

(defun mozc/init-mozc-popup ()
  (use-package mozc-popup
    :config
    ;; 変換候補をポップアップで表示させるようにする
    (setq mozc-candidate-style 'popup)))

(defun mozc/init-mozc-el-extensions ()
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

;;; packages.el ends here
