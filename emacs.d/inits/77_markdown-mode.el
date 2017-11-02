;;
;;; settings for markdown-mode
;;

;; ===================================================================

;; 【参考】EmacsでGithub flavorなMarkdownをプレビュー確認したい
;; http://blog.shinofara.xyz/archives/354/

;; ===================================================================

(el-get-bundle markdown-mode)

(use-package markdown-mode
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . gfm-mode)
         ("\\.markdown\\'" . markdown-mode))
  :init
  (setq initial-major-mode 'markdown-mode)
  (add-hook 'markdown-mode-hook
	    '(lambda ()
	       (electric-indent-local-mode -1)
	       (markdown-custom)))
  (add-hook 'gfm-mode-hook
	    '(lambda ()
	       (electric-indent-local-mode -1)))
  :config
  ;; ファイルパスを渡す
  (defun markdown-custom ()
    "markdown mode hook"
    (setq markdown-command-needs-filename t))
  )
