;;
;; setting for helm-swoop.el
;; https://github.com/ShingoFukuyama/helm-swoop

;; ===================================================================

;; 【参考】バッファ全体をMigemo絞り込み検索して走り回れ！
;; http://rubikitch.com/2014/12/25/helm-swoop/

;; ===================================================================


;; ===================================================================

;; 【Memo】
;; C-x c b (M-x helm-resume)で終了したhelm-swoopを復元する

;; ===================================================================

(el-get-bundle helm-swoop)

(use-package helm-swoop
  :defer t
  :commands (helm-swoop-nomigemo isearch-forward-or-helm-swoop)
  
  :bind (("M-o" . helm-swoop)
	 ("C-M-:" . helm-swoop-nomigemo)
	 ("C-s" . isearch-forward-or-helm-swoop))
  
  :config
  ;; 検索結果をcycleする、お好みで
  (setq helm-swoop-move-to-line-cycle t)
  
  ;; 画面を平行に分ける
  (setq helm-swoop-split-direction 'split-window-horizontally)

  (cl-defun helm-swoop-nomigemo (&key $query ($multiline current-prefix-arg))
    "シンボル検索用Migemo無効版helm-swoop"
    (interactive)
    (let ((helm-swoop-pre-input-function
  	   (lambda () (format "\\_<%s\\_> " (thing-at-point 'symbol)))))
      (helm-swoop :$source (delete '(migemo) (copy-sequence (helm-c-source-swoop)))
  		  :$query $query :$multiline $multiline)))

  (defun isearch-forward-or-helm-swoop (use-helm-swoop)
    (interactive "p")
    (let (current-prefix-arg
  	  (helm-swoop-pre-input-function 'ignore))
      (call-interactively
       (case use-helm-swoop
  	 (1 'isearch-forward)
  	 (4 'helm-swoop)
  	 (16 'helm-swoop-nomigemo)))))

  (bind-key "C-r" 'helm-previous-line helm-swoop-map)
  (bind-key "C-s" 'helm-next-line helm-swoop-map)
    
  )
