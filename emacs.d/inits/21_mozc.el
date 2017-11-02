;;
;; setting for mozc and the extensions
;; 
;; https://github.com/d5884/mozc-popup
;; https://github.com/iRi-E/mozc-el-extensions

;; ===================================================================

;; 【参考】Emacs:mozcで日本語入力
;; http://compress.hatenadiary.com/entry/2014/02/24/001932

;; ===================================================================

;; ==================================================================

;; 【参考】emacs-mozc を動かすための設定（emacs 設定編）
;; http://www49.atwiki.jp/ntemacs/pages/48.html

;; ===================================================================

(el-get-bundle google/mozc)

(use-package mozc
  :init
  (setq default-input-method "japanese-mozc")
  
  (add-hook 'mozc-mode-hook
	    (lambda()
	      (define-key mozc-mode-map (kbd "<zenkaku-hankaku>") 'toggle-input-method)
	      (define-key mozc-mode-map (kbd "M-`") 'toggle-input-method))
	    )
  
  ;; minibuffer に入った時、IME を OFF にする
  (add-hook 'minibuffer-setup-hook
	    (lambda ()
	      ;; isearch の中でなければ input-method を無効にする（他に良い判定方法があれば、変更してください）
	      (unless (memq 'isearch-done kbd-macro-termination-hook)
		(deactivate-input-method))))
  
  :bind
  ("<zenkaku-hankaku>" . toggle-input-method)
  ("M-`" . toggle-input-method)

  :config
  ;; helm でミニバッファの入力時に IME の状態を継承しない
  (setq helm-inherit-input-method nil)
  ;; helm で候補のアクションを表示する際に IME を OFF にする
  (advice-add 'helm-select-action
	      :before (lambda (&rest args)
			(deactivate-input-method)))
  )



(el-get-bundle d5884/mozc-popup)

(use-package mozc-popup
  :config
  ;; 変換候補をポップアップで表示させるようにする
  (setq mozc-candidate-style 'popup))



(el-get-bundle iRi-E/mozc-el-extensions)

(use-package mozc-cursor-color
  :init
  (add-hook 'mozc-im-activate-hook (lambda () (setq mozc-mode t)))
  (add-hook 'mozc-im-deactivate-hook (lambda () (setq mozc-mode nil)))

  :config
  ;; カーソルの色の設定
  (setq mozc-cursor-color-alist
	'((direct . "yellow")
	  (read-only . "lime green")
	  (hiragana . "dark orange")
	  (full-katakana . "goldenrod")
	  (half-ascii . "dark orchid")
	  (full-ascii . "orchid")
	  (half-katakana . "dark goldenrod")))
  
  )

(use-package mozc-mode-line-indicator)

(use-package mozc-isearch
    :disabled t)
