;;
;; settings for google-translate.el
;; https://github.com/atykhonov/google-translate

(el-get-bundle google-translate)

(use-package google-translate

  :defer t
  :bind ("C-c g t" . google-translate-enja-or-jaen)
  :config
  
  ;; Fix error of "Failed to search TKK"
  (defun google-translate--get-b-d1 ()
    ;; TKK='427110.1469889687'
    (list 427110 1469889687))

  (defvar google-translate-english-chars "[:ascii:]"
    "これらの文字が含まれているときは英語とみなす")
  
  (defun google-translate-enja-or-jaen (&optional string)
    "regionか、現在のセンテンスを言語自動判別でGoogle翻訳する。"
    (interactive)
    (setq string
	  (cond ((stringp string) string)
		(current-prefix-arg
		 (read-string "Google Translate: "))
		((use-region-p)
		 (buffer-substring (region-beginning) (region-end)))
		(t
		 (save-excursion
		   (let (s)
		     (forward-char 1)
		     (backward-sentence)
		     (setq s (point))
		     (forward-sentence)
		     (buffer-substring s (point)))))))
    (let* ((asciip (string-match
		    (format "\\`[%s]+\\'" google-translate-english-chars)
		    string)))
      (run-at-time 0.1 nil 'deactivate-mark)
      (google-translate-translate
       (if asciip "en" "ja")
       (if asciip "ja" "en")
       string)))

  ;;; 翻訳結果をkill-ringに保存するアドバイス
  (defadvice google-translate-paragraph (before
					 google-translate-paragraph-before)
    (when (equal 'google-translate-translation-face (ad-get-arg 1))
      (let ((text (ad-get-arg 0)))
	(kill-new text nil))))

  (ad-activate 'google-translate-paragraph))
