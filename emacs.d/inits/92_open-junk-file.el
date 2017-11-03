;;
;; setting for open-junk-file.el
;;

(el-get-bundle open-junk-file)

(use-package open-junk-file
    :config
  (setq open-junk-file-format "~/emacs.d/junk/%Y-%m-%d-%H%M%S."))
