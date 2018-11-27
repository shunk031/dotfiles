(require 'clang-format)

(provide 'c-c++-config)

(add-hook 'c-mode-common-hook
          (function (lambda ()
                      (add-hook 'before-save-hook
                                'clang-format-buffer))))
