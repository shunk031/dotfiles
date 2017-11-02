(el-get-bundle solarized-emacs)
(use-package solarized-theme
  ;; :disabled t
  :config
  (setq solarized-distinct-fringe-background t)
  (setq solarized-high-contrast-mode-line t)
  (setq solarized-use-more-italic t)
  (load-theme 'solarized-dark t))
