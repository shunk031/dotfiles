;;
;; setting for anzu.el
;; https://github.com/syohex/emacs-anzu

;; ===================================================================

;; 【参考】anzu.elの紹介
;; http://qiita.com/syohex/items/56cf3b7f7d9943f7a7ba

;; ===================================================================

(el-get-bundle anzu)

(use-package anzu
  :config
  (global-anzu-mode 1)
  (set-face-attribute 'anzu-mode-line nil
		      :foreground "yellow" :weight 'bold)

  (setq anzu-mode-lighter "")
  (setq anzu-deactivate-region t)
  (setq anzu-search-threshold 1000)
  (setq anzu-replace-to-string-separator " => "))
