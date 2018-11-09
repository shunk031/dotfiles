(require 'ispell)

(provide 'ispell-config)

(when (or (file-executable-p "/usr/bin/aspell") (file-executable-p "/usr/local/bin/aspell"))
  (setq-default ispell-program-name "aspell")

  ;; (setq ispell-extra-args '("--sug-mode=ultra" "--lang=en_US"))
  ;; パフォーマンス向上
  (add-to-list 'ispell-extra-args "--sug-mode=ultra")

  ;; 日本語はスキップ.
  (add-to-list 'ispell-skip-region-alist '("[^\000-\377]+")))
