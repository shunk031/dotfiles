;;
;; setting for multiple-cursor.el
;; https://github.com/magnars/multiple-cursors.el

;; ===================================================================

;; 【参考】emacs multiple-cursors.el : Emacsは忍者だった！
;; http://rubikitch.com/2014/11/10/multiple-cursors/

;; ===================================================================

;; ===================================================================

;; 【参考】multiple-cursors.el を使おう
;; http://nishikawasasaki.hatenablog.com/entry/2012/12/31/094349

;; ===================================================================

(el-get-bundle multiple-cursors)

(use-package multiple-cursors
  :defer t
  :bind (("C-c m e" . mc/mark-more-like-this-extended)
	 ("C-c m a" . mc/mark-all-like-this-dwim)))
