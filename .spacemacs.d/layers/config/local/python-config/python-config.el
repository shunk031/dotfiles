(require 'python)

(provide 'python-config)

(add-to-list 'exec-path "~/.pyenv/shims")
(setq py-autopep8-options '("--max-line-length=200"))
(setq flycheck-flake8-maximum-line-length 200)
(add-hook 'python-mode-hook 'py-autopep8-enable-on-save)
