;;; packages.el --- config layer packages file for Spacemacs.
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
;; added to `config-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `config/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `config/pre-init-PACKAGE' and/or
;;   `config/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst config-packages
  '(
    copy-file-on-save
    command-log-mode
    electric-operator
    highlight-symbol
    import-popwin
    rainbow-mode
    (pangu-spacing :location (recipe :fetcher github
                                     :repo "coldnew/pangu-spacing"
                                     :commit "a4463dbb74abdeddb6c1c132a1f8fcf67ed87498"))
    smart-newline
    (showkey :location (recipe :fetcher github
                               :repo "emacsmirror/showkey"))
    (ssh-config-mode :location (recipe :fetcher github
                                       :repo "jhgorrell/ssh-config-mode-el"
                                       :files ("ssh-config-mode.el" "ssh-config-keywords.txt")))
    google-translate
    (display-line-number-mode :location built-in)
    (undo-tree :location built-in)
    (view-mode :location built-in)
    (json-mode :location built-in)
    jsonnet-mode
    )
  )

(defun config/init-copy-file-on-save ()
  (use-package copy-file-on-save
    :after (projectile)
    :config
    (progn
      (spacemacs|diminish copy-file-on-save-mode "" "")
      (global-copy-file-on-save-mode))))

(defun config/init-command-log-mode ()
  (use-package command-log-mode
    ))

(defun config/init-display-line-number-mode ()
  (dolist (hook '(
                  prog-mode-hook
                  ))
    (add-hook hook 'display-line-numbers-mode)))

(defun config/init-electric-operator ()
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

(defun config/post-init-google-translate ()
  (use-package google-translate
    :commands(google-translate-translate)
    :init
    (progn
      (defvar google-translate-english-chars "[:ascii:]"
        "これらの文字が含まれているときは英語とみなす")

      ;; 翻訳結果をkill-ringに保存するアドバイス
      (defadvice google-translate-paragraph (before
                                             google-translate-paragraph-before)
        (when (equal 'google-translate-translation-face (ad-get-arg 1))
          (let ((text (ad-get-arg 0)))
            (kill-new text nil))))
      )
    )
  )

(defun config/init-highlight-symbol ()
  (use-package highlight-symbol
    :commands (highlight-symbol-mode)
    :init
    (progn
      (spacemacs|diminish highlight-symbol-mode "" "")
      (dolist (hook '(
                      prog-mode-hook
                      nxml-mode-hook
                      ))
        (add-hook hook 'highlight-symbol-mode))

      ;; ソースコードにおいてM-p/M-nでシンボル間を移動できるようにする
      (dolist (hook '(
                      prog-mode-hook
                      nxml-mode-hook
                      ))
        (add-hook hook 'highlight-symbol-nav-mode)))

    :config
    (progn
      ;; 1秒後自動ハイライトされるようになる
      (setq highlight-symbol-idle-delay 0.5)
      (setq highlight-symbol-colors '("HotPink1")))))

(defun config/init-import-popwin ()
  (use-package import-popwin
    :after(popwin)))

(defun config/init-rainbow-mode ()
  (use-package rainbow-mode
    :init
    (progn
      (spacemacs|diminish rainbow-mode "" "")

      (dolist (hook '(css-mode-hook
                      scss-mode-hook
                      html-mode-hook
                      emacs-lisp-mode-hook
                      nxml-mode-hook
                      )
                    )
        (add-hook hook 'rainbow-mode)))))

(defun config/init-pangu-spacing ()
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

(defun config/init-smart-newline ()
  (use-package smart-newline
    :init
    (dolist
        (hook
         '(
           markdown-mode-hook
           ))
      (add-hook hook
                (lambda ()
                  (smart-newline-mode t))))))

(defun config/init-showkey ()
  (use-package showkey))

(defun config/init-ssh-config-mode ()
  (use-package ssh-config-mode
    :init
    (add-hook 'ssh-config-mode-hook 'turn-on-font-lock)
    :config
    (progn
      (add-to-list 'auto-mode-alist '("/\\.ssh/config\\'"     . ssh-config-mode))
      (add-to-list 'auto-mode-alist '("/sshd?_config\\'"      . ssh-config-mode))
      (add-to-list 'auto-mode-alist '("/known_hosts\\'"       . ssh-known-hosts-mode))
      (add-to-list 'auto-mode-alist '("/authorized_keys2?\\'" . ssh-authorized-keys-mode)))))

(defun config/post-init-undo-tree ()
  (setq undo-tree-visualizer-timestamps nil)
  (setq undo-tree-visualizer-diff nil)
  ;; (spacemacs|use-package-add-hook popwin
  ;;   :post-config
  ;;   (push '(" *undo-tree*" :width 0.3 :position right) popwin:special-display-config)
  ;;   )
  )

(defun config/init-view-mode ()
  (add-hook 'view-mode-hook
            '(lambda ()
               (progn
                 (define-key view-mode-map (kbd "h") 'backward-char)
                 (define-key view-mode-map (kbd "j") 'next-line)
                 (define-key view-mode-map (kbd "k") 'previous-line)
                 (define-key view-mode-map (kbd "l") 'forward-char)))))

(defun config/post-init-json-mode ()
  (add-hook 'json-mode-hook 'highlight-indentation-current-column-mode))

(defun config/post-init-jsonnet-mode ()
  (add-hook 'jsonnet-mode-hook 'highlight-indentation-current-column-mode))
;;; packages.el ends here
