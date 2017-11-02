(el-get-bundle exec-path-from-shell)

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :init
  (setq exec-path-from-shell-arguments '("-l"))
  :config
  (progn
    (setq exec-path-from-shell-arguments '("-l"))
    (exec-path-from-shell-initialize)
    (let ((envs '("PATH" "GEM_PATH" "GEM_HOME" "GOPATH" "PYTHONPATH")))
      (exec-path-from-shell-copy-envs envs))))
