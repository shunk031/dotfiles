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
    ivy-rich

    ivy-posframe

    ;; ace-isearch
    ;; ace-jump-mode
    flyspell-correct

    (counsel-ghq :location (recipe :fetcher github
                                   :repo "SuzumiyaAoba/counsel-ghq"))
    )
  )

;; (defun my-ivy-config/init-ace-jump-mode ()
;;   (use-package ace-jump-mode
;;     :after (swiper avy)
;;     :defer t))

;; (defun my-ivy-config/init-ace-isearch ()
;;   (use-package ace-isearch
;;     :after (swiper avy)
;;     ;; :bind ("C-s" . isearch-forward)
;;     ;; :custom
;;     ;; (ace-isearch-function-from-isearch 'ace-isearch-swiper-from-isearch)
;;     :init
;;     (progn
;;       ;; (global-set-key (kbd "C-s") 'isearch-forward)
;;       (global-ace-isearch-mode t))))

(defun my-ivy-config/post-init-ivy ()
  (use-package ivy
    :config
    (progn
      (setq ivy-initial-inputs-alist nil)

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

(defun my-ivy-config/post-init-ivy-rich ()
  (use-package ivy-rich
    :config
    (progn
      (setcdr (assq t ivy-format-functions-alist) #'ivy-format-function-line)
      (setq ivy-rich-path-style 'abbreviate)

      (setq ivy-rich-display-transformers-list
            '(ivy-switch-buffer
              (:columns
               ((ivy-rich-candidate (:width 30))
                (ivy-rich-switch-buffer-size (:width 7))
                (ivy-rich-switch-buffer-indicators (:width 4 :face error :align right))
                (ivy-rich-switch-buffer-major-mode (:width 12 :face warning))
                (ivy-rich-switch-buffer-project (:width 15 :face success))
                (ivy-rich-switch-buffer-path
                 (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path
                                      x (ivy-rich-minibuffer-width 0.3))))))
               :predicate
               (lambda (cand) (get-buffer cand)))
              counsel-find-file
              (:columns
               ((ivy-read-file-transformer)
                (ivy-rich-counsel-find-file-truename (:face font-lock-doc-face))))
              counsel-M-x
              (:columns
               ((counsel-M-x-transformer (:width 40))
                (ivy-rich-counsel-function-docstring (:face font-lock-doc-face))))
              counsel-describe-function
              (:columns
               ((counsel-describe-function-transformer (:width 40))
                (ivy-rich-counsel-function-docstring (:face font-lock-doc-face))))
              counsel-describe-variable
              (:columns
               ((counsel-describe-variable-transformer (:width 40))
                (ivy-rich-counsel-variable-docstring (:face font-lock-doc-face))))
              counsel-recentf
              (:columns
               ((ivy-rich-candidate (:width 0.8))
                (ivy-rich-file-last-modified-time (:face font-lock-comment-face))))
              package-install
              (:columns
               ((ivy-rich-candidate (:width 30))
                (ivy-rich-package-version (:width 16 :face font-lock-comment-face))
                (ivy-rich-package-archive-summary
                 (:width 7 :face font-lock-builtin-face))
                (ivy-rich-package-install-summary (:face font-lock-doc-face))))))

      (declare-function project-roots "projects")
      (declare-function projectile-project-root "projectile")

      (defun ivy-rich-switch-buffer-path (candidate)
        (if-let ((result (ivy-rich--switch-buffer-root-and-filename candidate)))
            (cl-destructuring-bind (root . filename) result
              (cond
               ;; Case: absolute
               ((or (memq ivy-rich-path-style '(full absolute))
                    (and (null ivy-rich-parse-remote-file-path)
                         (or (file-remote-p root))))
                (or filename root))
               ;; Case: abbreviate
               ((memq ivy-rich-path-style '(abbreviate abbrev))
                (abbreviate-file-name (or filename root)))
               ;; Case: relative
               ((or (eq ivy-rich-path-style 'relative)
                    t)            ; make 'relative default
                (if (and filename root)
                    (let ((relative-path (string-remove-prefix root filename)))
                      (if (string= relative-path candidate)
                          (concat (file-name-as-directory
                                   (file-name-nondirectory
                                    (directory-file-name (file-name-directory
                                                          filename))))
                                  candidate)
                        relative-path))
                  ""))))
          ""))

      (defun ivy-rich--switch-buffer-root-and-filename (candidate)
        (let* ((buffer (get-buffer candidate))
               (truenamep t))
          (cl-destructuring-bind
              (filename directory mode)
              (ivy-rich--local-values
               buffer '(buffer-file-name default-directory major-mode))
            ;; Only make sense when `filename' and `root' are both not `nil'
            (unless (and filename
                         directory
                         (if (file-remote-p filename) ivy-rich-parse-remote-buffer t)
                         (not (eq mode 'dired-mode)))
              (setq truenamep nil))
            (when (and truenamep
                       (ivy-rich-switch-buffer-in-project-p candidate))
              ;; Find the project root directory or `default-directory'
              (setq directory (cond ((bound-and-true-p projectile-mode)
                                     (or (ivy-rich--local-values
                                          buffer 'projectile-project-root)
                                         (with-current-buffer buffer
                                           (projectile-project-root))))
                                    ((require 'project nil t)
                                     (with-current-buffer buffer
                                       (setq truenamep nil)
                                       (car (project-roots (project-current))))))))
            (progn
              (if (not (eq mode 'dired-mode))
                  (setq filename (or (ivy-rich--local-values
                                      buffer 'buffer-file-truename)
                                     (file-truename filename)))
                (setq filename ""))
              (cons (expand-file-name directory)
                    (expand-file-name filename))))))

      )
    ))

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
