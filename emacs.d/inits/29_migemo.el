(el-get-bundle emacs-jp/migemo)

(use-package migemo
  
  :config
  (setq migemo-command "cmigemo")
  (setq migemo-options '("-q" "--emacs"))

  ;; cmigemoのpathを指定
  ;; (setq migemo-dictionary "/usr/share/cmigemo/utf-8/migemo-dict")
  (setq migemo-dictionary "/usr/local/share/migemo/utf-8/migemo-dict")
  
  (setq completion-ignore-case t)
  (setq migemo-user-dictionary nil)
  (setq migemo-regex-dictionary nil)
  (setq migemo-coding-system 'utf-8-unix)
  (migemo-init))
