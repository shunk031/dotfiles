;;
;; setting for undo-tree.el
;; http://www.dr-qubit.org/undo-tree/undo-tree.el

;; ===================================================================

;; 【参考】undo-tree.el の導入
;; http://d.hatena.ne.jp/khiker/20100123/undo_tree

;; ===================================================================

(el-get-bundle undo-tree)

(use-package undo-tree
  ;; :defer t を入れると発動しなくなってしまうから注意 
  :config
  (global-undo-tree-mode t))
