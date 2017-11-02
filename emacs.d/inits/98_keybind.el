;; Ctrl-x p で逆向きへのウィンドウ移動
(global-set-key (kbd "C-x p") (lambda () (interactive) (other-window -1)))


;; Undo( C-z )
(global-set-key (kbd "C-z") 'undo)


;; 切り取り( C-w )


;; コピー ( C-x w )
(global-set-key (kbd "C-x w") 'copy-region-as-kill)


;; 貼り付け( C-y )


;; shellを起動( C-c s )
;; (global-set-key (kbd"C-c s") 'shell)


;; eshellを起動( C-c s )
;; (global-set-key (kbd"C-c s") 'eshell)


;; C-c c で compile コマンドを呼び出す
(define-key mode-specific-map "c" 'compile)


;; M-/でredoする
;; (global-set-key (kbd "M-/") 'undo-tree-redo)


;; C-x b で anything-for-files を呼び出す
;;(global-set-key (kbd "C-x b") 'anything-for-files)


;; C-x b でhelm-for-files を呼び出す
;; (global-set-key (kbd "C-x b") 'helm-for-files)


;; C-c q で quickrun を呼び出す
(global-set-key (kbd "C-c q") 'quickrun)


;; C-x C-b で ibuffer を呼び出す
(global-set-key (kbd "C-x C-b") 'ibuffer)


;; C-x m で magit-status を呼び出す
;; (global-set-key (kbd "C-x m") 'magit-status)


;; C-c ; で コメント、アンコメントする
(global-set-key (kbd "C-c ;") 'comment-or-uncomment-region)


;; C-x C-z でウィンドウを最小化しないようにする
(global-set-key (kbd "C-x C-z") nil)


;; RET でsmart-newlineを発動
(global-set-key (kbd "RET") 'smart-newline)


;; C-#(C-M-3)でコメントを折りたたむ
(global-set-key (kbd "C-#") 'hs-toggle-hiding)



;; C-x C-M-k でEmacsを終了させる 
(global-set-key (kbd "C-x C-M-k") 'save-buffers-kill-emacs)



;; C-x C-j でopen-junk-fileを発動
(global-set-key (kbd "C-x C-j") 'open-junk-file)


;; C-h でbackspace
(global-set-key (kbd "C-h") 'delete-backward-char)


;; C-c C-vでview-mode
(global-set-key (kbd "C-c <escape>") 'view-mode)


;; US配列時に日本語入力モードにする
(global-set-key (kbd "M-`") nil)
(global-set-key (kbd "M-`") 'toggle-input-method)


;; C-x C-p のmark-pageを使わないようにする
(global-set-key (kbd "C-x C-p") nil)



;; ===================================================================

;; yank した瞬間にインデントする
;; http://d.hatena.ne.jp/yascentur/20120228/1330355171

;; ===================================================================

(global-set-key (kbd "C-M-y")
		(lambda ()
		  (interactive)
		  (yank)
		  (indent-region (region-beginning) (region-end))))

;; C-x C-jでopen-junk-fileを発動
(global-set-key (kbd "C-x C-j") 'open-junk-file)
