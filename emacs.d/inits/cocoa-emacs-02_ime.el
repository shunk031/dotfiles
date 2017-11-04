;; Emacs Mac Port 用設定
;; ミニバッファで入力する際に自動的にASCIIにする
;; (when (fboundp 'mac-auto-ascii-mode)
;;   (mac-auto-ascii-mode 1))

;; ;; カーソルの色を変える
(when (fboundp 'mac-input-source)
  (defun my-mac-selected-keyboard-input-source-chage-function ()
    "英語のときはカーソルの色をdim grayに、日本語のときはbrownにします."
    (let ((mac-input-source (mac-input-source)))
      (set-cursor-color
       (if (string-match "com.apple.keylayout.US" mac-input-source)
           "yellow" "orange"))))
  (add-hook 'mac-selected-keyboard-input-source-change-hook
            'my-mac-selected-keyboard-input-source-chage-function))
