;;
;; setting for popwin.el
;; https://github.com/m2ym/popwin-el

;; ===================================================================

;; 【参考】ヘルプバッファや補完バッファを
;;         ポップアップで表示してくれるpopwin.elをリリースしました
;; http://d.hatena.ne.jp/m2ym/20110120/1295524932

;; ===================================================================

(el-get-bundle popwin)

(use-package popwin
  ;; :defer t を入れると発動しなくなってしまうから注意
  :config
  (popwin-mode 1)

  (setq popwin:adjust-other-windows t)
  
  ;; *quickrun* バッファをポップアップ表示させる
  (push '("*quickrun*") popwin:special-display-config)

  ;; *helm* バッファをポップアップ表示させる
  (setq helm-full-frame nil)
  (push '("^\*helm .+\*$" :regexp t :height 25) popwin:special-display-config)

  ;; direx-mode バッファをポップアップ表示させる
  (push '(direx:direx-mode :position left :width 40 :dedicated t) popwin:special-display-config)

  ;; magitの COMMIT_EDITMSG バッファをポップアップ表示させる
  (push '("COMMIT_EDITMSG" :height 0.3) popwin:special-display-config)

  ;; recentf-extの *Open Recent* バッファをポップアップ表示させる
  (push '("*Open Recent*" :height 25) popwin:special-display-config)

  ;; undo-treeの *undo-tree* バッファをポップアップ表示させる
  (push '("*undo-tree*" :width 0.3 :position right) popwin:special-display-config)

  (use-package popwin-yatex
    :defer t
    :config
    ;; yatex-modeの *YaTeX-typesetting* バッファをポップアップ表示させる
    (push '("*YaTeX-typesetting*") popwin:special-display-config))
  
  ;; (require 'popwin-yatex) するとエラーが出るから、
  ;; popwin-yatexのコードをここに転記した
  ;; (defadvice YaTeX-showup-buffer
  ;;     (around popwin-yatex:YaTeX-showup-buffer (buffer &optional func select) activate)
  ;;   (popwin:display-buffer-1 buffer
  ;; 			     :default-config-keywords `(:noselect ,(not select))
  ;; 			     :if-config-not-found (lambda (buffer) ad-do-it)))

  ;; yatex-modeの *dvi-preview* バッファをポップアップ表示させる
  (push '("*dvi-preview*" :height 10) popwin:special-display-config)

  ;; yatex-modeの *YaTeX-typesetting* バッファをポップアップ表示させる
  ;; (push '("*YaTeX-typesetting*") popwin:special-display-config)

  ;; *compilation* バッファをポップアップ表示させる
  (push '("*compilation*" :height 10) popwin:special-display-config)
  
  ;; R data view バッファをポップアップ表示させる
  ;; 動かない
  ;; (push '("R data view" :position right) popwin:special-display-config)

  (push '("*Google Translate*" :position bottom) popwin:special-display-config)

  ;; (setq popwin:special-display-config
  ;; 	'((magit-status-mode :position right :width 60)))
  
  )
