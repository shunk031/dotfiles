;;
;; settings for Emacs frame

;; 初期フレームの設定
(setq initial-frame-alist
      (append (list
	       '(width . 203)
	       '(height . 60)
	       '(top . 0)
	       '(left . 0)
	       )
	      initial-frame-alist))

;; 新規フレームのデフォルト設定
(setq default-frame-alist initial-frame-alist)
