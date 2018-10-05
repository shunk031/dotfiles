;;
;; setting for yasnippet.el
;; https://github.com/joaotavora/yasnippet

;; ===================================================================

;; 【参考】yasnippet 8.0の導入からスニペットの書き方、
;;                           anything/helm/auto-completeとの連携
;; 
;; http://fukuyama.co/yasnippet

;; 閲覧・編集([C-x i v] or M-x yas-visit-snippet-file)はanything/helm
;; では出てこないから、 yasnippet.elの2371行目yas-visit-snippet-file関数
;; 中の(yas-prompt-functions '(yas-ido-prompt yas-completing-prompt))
;; を;; コメントアウトする。一時的なプロンプト変更処理を抑制するためである。
;; これでanything/helmインターフェースに対応する。

;; ===================================================================

(el-get-bundle yasnippet)

(use-package yasnippet
  ;; :defer t
  :diminish yas-minor-mode
  :config
  (setq yas-snippet-dirs
	'("~/.emacs.d/snippets/mysnippets"      ;; 作成したスニペット
	  "~/.emacs.d/snippets/site-snippets"   ;; 拾ってきたスニペット
	  ))

  (yas-global-mode 1)

  (bind-key "C-x i i" 'yas-insert-snippet yas-minor-mode-map)
  (bind-key "C-x i n" 'yas-new-snippet yas-minor-mode-map)
  (bind-key "C-x i v" 'yas-visit-snippet-file yas-minor-mode-map)
  (bind-key "C-o" 'yas-expand yas-minor-mode-map)
  (bind-key "TAB" nil yas-minor-mode-map))
