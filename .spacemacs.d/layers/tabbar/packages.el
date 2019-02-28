;;; packages.el --- tabbar layer packages file for Spacemacs.
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
;; added to `tabbar-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `tabbar/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `tabbar/pre-init-PACKAGE' and/or
;;   `tabbar/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst tabbar-packages
  '(
    tabbar
    )
  "The list of Lisp packages required by the tabbar layer.

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


(defun tabbar/init-tabbar ()
  (use-package tabbar
    :init
    (progn
      (tabbar-mode 1)
      ;; バッファに変更があった場合に表示を変更する
      ;; タブラベルに空間をもたせる
      ;; (defadvice tabbar-buffer-tab-label (after fixup_tab_label_space_and_flag activate)
      ;;   (setq ad-return-value
      ;;         (if (and (buffer-modified-p (tabbar-tab-value tab))
      ;;                  (buffer-file-name (tabbar-tab-value tab)))
      ;;             (concat "▼  " (concat ad-return-value "  ▼ "))
      ;;           (concat " " (concat ad-return-value " ")))))

      ;; Called each time the modification state of the buffer changed.
      (defun ztl-modification-state-change ()
        (tabbar-set-template tabbar-current-tabset nil)
        (tabbar-display-update))

      ;; First-change-hook is called BEFORE the change is made.
      (defun ztl-on-buffer-modification ()
        (set-buffer-modified-p t)
        (ztl-modification-state-change))
      (add-hook 'after-save-hook 'ztl-modification-state-change)

      ;; This doesn't work for revert, I don't know.
      ;; (add-hook 'after-revert-hook 'ztl-modification-state-change)
      (add-hook 'first-change-hook 'ztl-on-buffer-modification)

      ;; 左に表示されるボタンの無効化
      (dolist (btn '(tabbar-buffer-home-button
                     tabbar-scroll-left-button
                     tabbar-scroll-right-button))
        (set btn (cons (cons "" nil)
                       (cons "" nil))))

      ;; グループ化しないようにする
      (setq tabbar-buffer-groups-function nil)

      (setq tabbar-use-images nil)

      ;; 除外するバッファを指定
      (setq my/tabbar-exclude-buffer-regex
            (format "%s.*" (regexp-opt '("magit-process:"
                                        "magit-diff:"))))
      ;; 「*」で始まるバッファをタブとして表示しない
      (defun my/tabbar-buffer-list ()
        (delq nil
              (mapcar #'(lambda (b)
                          (cond
                           ;; Always include the current buffer.
                           ((eq (current-buffer) b) b)
                           ((buffer-file-name b) b)
                           ((char-equal ?\  (aref (buffer-name b) 0)) nil)
                           ((equal "*scratch*" (buffer-name b)) b)       ; *scratch*バッファは表示する
                           ((equal "*Open Recent*" (buffer-name b)) b)   ; *Open Recent*バッファは表示する
                           ((string-match my/tabbar-exclude-buffer-regex (buffer-name b)) nil) ; 除外するバッファを指定
                           ((char-equal ?* (aref (buffer-name b) 0)) nil) ; それ以外の * で始まるバッファは表示しない
                           ((buffer-live-p b) b)))
                      (buffer-list))))
      (setq tabbar-buffer-list-function 'my/tabbar-buffer-list)

      ;; Ctrl-Tab, Ctrl-Shift-Tab でタブを切り替える
      (global-set-key (kbd "<C-tab>") 'tabbar-forward-tab)
      (global-set-key (kbd "<C-iso-lefttab>") 'tabbar-backward-tab)
      (global-set-key (kbd "<C-S-tab>") 'tabbar-backward-tab)

      ;; ウインドウからはみ出たタブを省略して表示
      (setq tabbar-auto-scroll-flag nil)

      ;; タブとタブの間の長さ
      (setq tabbar-separator '(0.5))

      (set-face-attribute 'tabbar-default nil
                          :background nil
                          :distant-foreground nil
                          ;; :family "Monaco"
                          :box nil
                          )
      (set-face-attribute 'tabbar-unselected nil
                          :background nil
                          :foreground "white"
                          :box nil)
      (set-face-attribute 'tabbar-modified nil
                          :foreground "red4"
                          :box nil
                          :inherit 'tabbar-unselected)
      (set-face-attribute 'tabbar-selected nil
                          :background "#6CB2E9"
                          :foreground "white"
                          :box nil)
      (set-face-attribute 'tabbar-selected-modified nil
                          :inherit 'tabbar-selected
                          :foreground "GoldenRod2"
                          :box nil)
      (set-face-attribute 'tabbar-button nil
                          :box nil)

      ;; (set-face-attribute 'tabbar-default nil
      ;;                     :background "#586e75"
      ;;                     :foreground "#586e75"
      ;;                     :distant-foreground "gray50"
      ;;                     :family "Monaco"
      ;;                     :box nil)
      ;; (set-face-attribute 'tabbar-unselected nil
      ;;                     :background "#657b83"
      ;;                     :foreground "white"
      ;;                     :box nil)
      ;; (set-face-attribute 'tabbar-modified nil
      ;;                     :inherit 'tabbar-unselected)
      ;; (set-face-attribute 'tabbar-selected nil
      ;;                     :background "#2aa198"
      ;;                     :foreground "white"
      ;;                     :box nil)
      ;; (set-face-attribute 'tabbar-selected-modified nil
      ;;                     :inherit 'tabbar-selected
      ;;                     :box nil)
      ;; (set-face-attribute 'tabbar-button nil
      ;;                     :box nil)

      ;; (set-face-attribute
      ;;  'tabbar-default nil
      ;;  :family "Monaco"
      ;;  :background "#586e75"
      ;;  :foreground "#586e75"
      ;;  :box nil)

      ;; (set-face-attribute
      ;;  'tabbar-unselected nil
      ;;  :background "#657b83"
      ;;  :foreground "white"
      ;;  :box nil)

      ;; (set-face-attribute
      ;;  'tabbar-modified nil
      ;;  :background "#657b83"
      ;;  :foreground "white"
      ;;  :box nil)

      ;; (set-face-attribute
      ;;  'tabbar-selected nil
      ;;  :background "#2aa198"
      ;;  :foreground "white"
      ;;  :box nil)

      ;; (set-face-attribute
      ;;  'tabbar-button nil
      ;;  :box nil)

      ;; (set-face-attribute
      ;;  'tabbar-selected-modified nil
      ;;  :background "#2aa198"
      ;;  :foreground "white"
      ;;  :box nil)

      ;; (set-face-attribute
      ;;  'tabbar-separator nil
      ;;  :background "#002b36"
      ;;  :foreground "#002b36"
      ;;  :box nil)

      ;; tabbar-selected を太字で表示
      (set-face-bold-p 'tabbar-selected t)

      ;; tabbar-selected-modified を太字で表示
      (set-face-bold-p 'tabbar-selected-modified t)

      ;; tabbar-modified を太字で表示
      (set-face-bold-p 'tabbar-modified t)

      (defvar my/tabbar-height 24)
      (defvar my/tabbar-left (powerline-wave-right 'tabbar-default nil my/tabbar-height))
      (defvar my/tabbar-right (powerline-wave-left nil 'tabbar-default my/tabbar-height))
      (defun my/tabbar-tab-label-function (tab)
        (powerline-render (list my/tabbar-left
                                (format " %s  " (car tab))
                                my/tabbar-right)))
      (setq tabbar-tab-label-function #'my/tabbar-tab-label-function)
      )
    )
  )

;;; packages.el ends here
