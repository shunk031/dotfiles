;;
;; setting for dired-mode.el
;;

;; ===================================================================

;; 【参考】diredでディレクトリを開くときにバッファを複数作成しないTIPS
;; http://tam5917.hatenablog.com/entry/20130126/1359206522

;; ===================================================================

(use-package dired
  :init
  (bind-key "r" 'wdired-change-to-wdired-mode dired-mode-map)
  
  :config
  ;; diredでディレクトリを開くときにバッファを複数作成しないようにする
  (defun dired-open-in-accordance-with-situation ()
    (interactive)
    (let ((file (dired-get-filename)))
      (if (file-directory-p file)
	  (dired-find-alternate-file)
	(dired-find-file))))

  ;; dired-find-alternate-file の有効化
  (put 'dired-find-alternate-file 'disabled nil)

  ;; RET 標準の dired-find-file では dired バッファが複数作られるので
  ;; dired-find-alternate-file を代わりに使う
  ;;(define-key dired-mode-map (kbd "RET") 'dired-open-in-accordance-with-situation)
  ;;(define-key dired-mode-map (kbd "a") 'dired-find-file)

  ;; diredバッファでC-sした時にファイル名だけにマッチするように
  (setq dired-isearch-filenames t)
  
  )
