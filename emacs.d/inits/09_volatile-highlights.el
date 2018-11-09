;;
;; setting for volatile-highlights.el
;; https://github.com/k-talo/volatile-highlights.el

;; ===================================================================

;; 操作に視覚的フィードバックを与える
;; https://github.com/k-talo/volatile-highlights.el/blob/master/README-ja.org

;; ===================================================================

(el-get-bundle volatile-highlights)

(use-package volatile-highlights
  :config
  (volatile-highlights-mode t)
  
  ;; undo-treeに対応させる
  (vhl/define-extension 'undo-tree 'undo-tree-yank 'undo-tree-move)
  (vhl/install-extension 'undo-tree))
