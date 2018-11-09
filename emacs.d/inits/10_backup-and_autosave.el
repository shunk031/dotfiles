;; バックアップファイルを作成する
(setq make-backup-files t)

;; オートセーブファイルを作成する
(setq auto-save-default t)

;; バックアップとオートセーブファイルを
;; ~/emacs.d/backup/ へ集める
(add-to-list 'backup-directory-alist
             (cons "." "~/dotfiles/emacs.d/backups/"))
(setq auto-save-file-name-transformsp
      `((".*" ,(expand-file-name "~/dotfiles/emacs.d/backups/") t)))
