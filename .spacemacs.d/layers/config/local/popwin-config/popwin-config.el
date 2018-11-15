(require 'popwin)

(provide 'popwin-config)

;; undo-treeの *undo-tree* バッファをポップアップ表示させる
(push '(" *undo-tree*" :width 0.3 :position right) popwin:special-display-config)

;; yatex-modeの *dvi-preview* バッファをポップアップ表示させる
(push '(" *dvi-preview*" :height 10 :position right) popwin:special-display-config)

;; yatex-modeの *YaTeX-typesetting* バッファをポップアップ表示させる
(push '("*YaTeX-typesetting*") popwin:special-display-config)
(push '("*YaTeX-bibtex*") popwin:special-display-config)

(push '("*Google Translate*" :position bottom) popwin:special-display-config)
