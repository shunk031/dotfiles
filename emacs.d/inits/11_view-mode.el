;;
;;; setting for view-mode
;;

(add-hook 'view-mode-hook
	  '(lambda ()
	     (progn
	       (define-key view-mode-map (kbd "h") 'backward-char)
	       (define-key view-mode-map (kbd "j") 'next-line)
	       (define-key view-mode-map (kbd "k") 'previous-line)
	       (define-key view-mode-map (kbd "l") 'forward-char))))
