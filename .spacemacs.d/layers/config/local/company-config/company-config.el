(require 'company)

(provide 'company-config)

(setq company-tooltip-limit 20)
(setq company-idle-delay 0.1)
(setq company-require-match nil)

(define-key company-active-map (kbd "<tab>") 'company-complete-selection)
