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
    all-the-icons-ivy
    ace-isearch
    ace-jump-mode
    flyspell-correct
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
      (global-ace-isearch-mode t)
      )
    )
  )

(defun my-ivy-config/post-init-ivy ()
  (setq ivy-initial-inputs-alist nil)

  (setq ivy-sort-matches-functions-alist
        '((t)
          (ivy-switch-buffer . ivy-sort-function-buffer)
          (counsel-find-file . ivy--sort-by-length)))

  (defun ivy--sort-by-length (_name candidates)
    (cl-sort (copy-sequence candidates)
             (lambda (f1 f2)
               (< (length f1) (length f2)))))

  (bind-key "C-c i" 'counsel-imenu)
  (bind-key "C-x C-r" 'counsel-recentf)
  (bind-key "M-y" 'counsel-yank-pop)
  (bind-key "M-o" 'spacemacs/swiper-region-or-symbol)

  (define-key counsel-find-file-map (kbd "C-l") 'counsel-up-directory)
  (define-key counsel-find-file-map (kbd "C-i") 'counsel-down-directory)
  (define-key counsel-find-file-map (kbd "C-h") nil)

  (defun my/swiper-replace ()
    "Swiper replace with mc selction."
    (interactive)
    (run-at-time nil nil (lambda ()
                           (ivy-wgrep-change-to-wgrep-mode)))
    (ivy-occur))
  (define-key ivy-minibuffer-map (kbd "C-c C-e") 'my/swiper-replace)
  )

(defun my-ivy-config/init-all-the-icons-ivy ()
  (use-package all-the-icons-ivy
    :init
    (all-the-icons-ivy-setup)))

(defun my-ivy-config/init-ivy-posframe ()
  (use-package ivy-posframe
    :after ivy
    :custom-face
    (ivy-posframe ((t (:background "#282a36"))))
    (ivy-posframe-border ((t (:background "#6272a4"))))
    (ivy-posframe-cursor ((t (:background "#61bfff"))))
    :init
    (progn
      (setq ivy-display-function #'ivy-posframe-display-at-frame-center)
      (setq ivy-posframe-parameters
            '((left-fringe . 8)
              (right-fringe . 8)))
      (ivy-posframe-enable))))

(defun my-ivy-config/post-init-flyspell-correct ()
    (use-package flyspell-correct-ivy
      :bind ("C-M-;" . flyspell-correct-wrapper)
      :init
      (setq flyspell-correct-interface #'flyspell-correct-ivy)))

;;; packages.el ends here
