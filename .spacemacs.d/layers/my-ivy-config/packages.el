;;; packages.el --- my-ivy-config layer packages file for Spacemacs.
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
;; added to `my-ivy-config-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `my-ivy-config/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `my-ivy-config/pre-init-PACKAGE' and/or
;;   `my-ivy-config/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst my-ivy-config-packages
  '(
    (ivy :location built-in)

    ivy-posframe

    ace-isearch
    ace-jump-mode
    flyspell-correct

    (counsel-ghq :location (recipe :fetcher github
                                   :repo "windymelt/counsel-ghq"))
    )
  )

(defun my-ivy-config/init-ace-jump-mode ()
  (use-package ace-jump-mode
    :defer t))

(defun my-ivy-config/init-ace-isearch ()
  (use-package ace-isearch
    :after (swiper avy)
    :custom
    (ace-isearch-function-from-isearch 'ace-isearch-swiper-from-isearch)
    :init
    (progn
      (global-set-key (kbd "C-s") 'isearch-forward)
      (global-ace-isearch-mode t))))

(defun my-ivy-config/post-init-ivy ()
  (use-package ivy
    :config
    (progn
      (setq ivy-initial-inputs-alist nil)

      ;;; 選択対象を "" にする (requires all-the-icons.el)
      (defface my-ivy-arrow-visible
        '((((class color) (background light)) :foreground "orange")
          (((class color) (background dark)) :foreground "#EE6363"))
        "Face used by Ivy for highlighting the arrow.")
      (defface my-ivy-arrow-invisible
        '((((class color) (background light)) :foreground "#FFFFFF")
          (((class color) (background dark)) :foreground "#31343F"))
        "Face used by Ivy for highlighting the invisible arrow.")
      (if window-system
          (when (require 'all-the-icons nil t)
            (defun my-ivy-format-function-arrow (cands)
              "Transform CANDS into a string for minibuffer."
              (ivy--format-function-generic
               (lambda (str)
                 (concat (all-the-icons-faicon
                          "hand-o-right"
                          :v-adjust -0.2 :face 'my-ivy-arrow-visible)
                         " " (ivy--add-face str 'ivy-current-match)))
               (lambda (str)
                 (concat (all-the-icons-faicon
                          "hand-o-right" :face 'my-ivy-arrow-invisible) " " str))
               cands
               "\n"))
            (setq ivy-format-functions-alist
                  '((t . my-ivy-format-function-arrow))))
        (setq ivy-format-functions-alist '((t . ivy-format-function-arrow))))

      (setq ivy-sort-matches-functions-alist
            '((t)
              (ivy-switch-buffer . ivy-sort-function-buffer)
              (counsel-find-file . spacemacs//ivy--sort-by-length)))

      (bind-key "C-c i" 'counsel-imenu)
      (bind-key "C-x C-r" 'counsel-recentf)
      (bind-key "M-y" 'counsel-yank-pop)
      (bind-key "M-o" 'spacemacs/swiper-region-or-symbol)

      (define-key counsel-find-file-map (kbd "C-l") 'counsel-up-directory)
      (define-key counsel-find-file-map (kbd "C-i") 'counsel-down-directory)
      (define-key counsel-find-file-map (kbd "C-h") nil)
      (define-key ivy-minibuffer-map (kbd "C-c C-e") 'spacemacs/swiper-replace))))

(defun my-ivy-config/init-ivy-posframe ()
  (use-package ivy-posframe
    :after ivy
    :custom-face
    (ivy-posframe ((t (:background "#282a36"))))
    (ivy-posframe-border ((t (:background "#6272a4"))))
    (ivy-posframe-cursor ((t (:background "#61bfff"))))
    :init
    (progn
      (setq ivy-posframe-display-functions-alist
            '(
              (swiper . nil)
              (t      . ivy-posframe-display-at-frame-center)
              ))

      (setq ivy-posframe-height-alist '((swiper . 20)
                                        (t      . 30)))
      (setq ivy-posframe-parameters
            '((left-fringe . 10)
              (right-fringe . 10)))

      (ivy-posframe-mode 1)
      )))

(defun my-ivy-config/init-counsel-ghq ()
  (use-package counsel-ghq
    :bind ("C-c g h q" . counsel-ghq)
    ))

(defun my-ivy-config/post-init-flyspell-correct ()
    (use-package flyspell-correct-ivy
      :bind ("C-M-;" . flyspell-correct-wrapper)
      :init
      (setq flyspell-correct-interface #'flyspell-correct-ivy)))

;;; packages.el ends here
