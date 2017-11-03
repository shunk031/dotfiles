;;
;; setting for ssh config file
;; https://github.com/jhgorrell/ssh-config-mode-el
;;

(el-get-bundle jhgorrell/ssh-config-mode-el)
(use-package ssh-config-mode
  :init
  (add-hook 'ssh-config-mode-hook 'turn-on-font-lock)
  :config
  (add-to-list 'auto-mode-alist '("/\\.ssh/config\\'"     . ssh-config-mode))
  (add-to-list 'auto-mode-alist '("/sshd?_config\\'"      . ssh-config-mode))
  (add-to-list 'auto-mode-alist '("/known_hosts\\'"       . ssh-known-hosts-mode))
  (add-to-list 'auto-mode-alist '("/authorized_keys2?\\'" . ssh-authorized-keys-mode)))
