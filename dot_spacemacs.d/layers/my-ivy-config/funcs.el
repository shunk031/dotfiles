(defun spacemacs//ivy--sort-by-length (_name candidates)
  (cl-sort (copy-sequence candidates)
           (lambda (f1 f2)
             (< (length f1) (length f2)))))

(defun spacemacs/swiper-replace ()
  "Swiper replace with mc selction."
  (interactive)
  (run-at-time nil nil (lambda ()
                         (ivy-wgrep-change-to-wgrep-mode)))
  (ivy-occur))

;; fix for avy-migemo-mode
;; (defun swiper--add-overlay (beg end face wnd priority)
;;   (let ((overlay (make-overlay beg end)))
;;     (overlay-put overlay 'face face)
;;     (overlay-put overlay 'window wnd)
;;     (overlay-put overlay 'priority priority)
;;     overlay))

(defun counsel-flycheck ()
    (interactive)
    (if (not (bound-and-true-p flycheck-mode))
      (message "Flycheck mode is not available or enabled")
      (ivy-read "Error: "
        (let ((source-buffer (current-buffer)))
          (with-current-buffer (or (get-buffer flycheck-error-list-buffer)
                                 (progn
                                   (with-current-buffer
                                     (get-buffer-create flycheck-error-list-buffer)
                                     (flycheck-error-list-mode)
                                     (current-buffer))))
            (flycheck-error-list-set-source source-buffer)
            (flycheck-error-list-reset-filter)
            (revert-buffer t t t)
            (split-string (buffer-string) "\n" t " *")))
        :action (lambda (s &rest _)
                  (-when-let* ( (error (get-text-property 0 'tabulated-list-id s))
                                (pos (flycheck-error-pos error)) )
                    (goto-char (flycheck-error-pos error))))
        :history 'counsel-flycheck-history)))
