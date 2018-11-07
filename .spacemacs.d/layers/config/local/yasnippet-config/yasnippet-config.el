(require 'yasnippet)

(provide 'yasnippet-config)

(setq yas-snippet-dirs (append yas-snippet-dirs
                               '(
                                 "~/.spacemacs.d/snippets/site-snippets"
                                 "~/.spacemacs.d/snippets/my-snipptes"
                                )))

(define-key yas-minor-mode-map (kbd "TAB") 'hippie-expand)
