(require 'popwin)

(provide 'popwin-config)

;; undo-treeの *undo-tree* バッファをポップアップ表示させる
(push '(" *undo-tree*" :width 0.3 :position right) popwin:special-display-config)
