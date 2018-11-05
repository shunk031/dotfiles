(provide 'basic-config)

(setq frame-title-format
      (format "- Emacs@%s - %%f" (system-name)))

(setq blink-cursor-interval 0.08)
(setq blink-cursor-delay 0.05)
(blink-cursor-mode 1)
