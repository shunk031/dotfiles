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
(defun swiper--add-overlay (beg end face wnd priority)
  (let ((overlay (make-overlay beg end)))
    (overlay-put overlay 'face face)
    (overlay-put overlay 'window wnd)
    (overlay-put overlay 'priority priority)
    overlay))
