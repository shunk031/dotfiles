;;
;; setting for helm-ag.el
;; https://github.com/syohex/emacs-helm-ag

;; ===================================================================

;; 【参考】helm-agを書きました
;; http://d.hatena.ne.jp/syohex/20130302/1362182193

;; ===================================================================

(el-get-bundle helm-ag)

(use-package helm-ag
  :defer t
  :commands helm-ag-dot-emacs
  :init (use-package helm-files)
  :bind
  (("C-M-g" . helm-ag)
   ("C-M-k" . backward-kill-sexp))
  
  :config
  
  ;; 現在のシンボルをデフォルトのクエリにする
  (setq helm-ag-insert-at-point 'symbol)
  
  ;; .emacs.d以下を検索する M-x helm-ag-dot-emacs を定義
  (defun helm-ag-dot-emacs ()
    ".emacs.d以下を検索"
    (interactive)
    (helm-ag "~/.emacs.d/")))
