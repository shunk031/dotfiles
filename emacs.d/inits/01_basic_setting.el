;;
;; basic settings
;;

;; 日本語を utf-8 に統一
(set-language-environment "Japanese")
(setq buffer-file-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-clipboard-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)
(prefer-coding-system 'utf-8)



;; フォントをRitcyに変更する
;; (add-to-list 'default-frame-alist '(font . "s2g love font-14"))
;; (add-to-list 'default-frame-alist '(font . "ricty-12"))
;; (custom-set-faces
;;  '(variable-pitch ((t (:family "Ricty"))))
;;  '(fixed-pitch ((t (:family "Ricty")))))
;; (set-default-font "Ricty Diminished")
(add-to-list 'default-frame-alist '(font . "Ricty Diminished-15"))



;; スクリーンの最大化
(when (eq system-type 'gnu/linux)
  (set-frame-parameter nil 'fullscreen 'maximized))


;; yes/no を y/n とする。
(fset 'yes-or-no-p 'y-or-n-p)



;; 終了時に自動でプロセスをkill
;; (defadvice save-buffers-kill-emacs (around no-query-kill-emacs activate)
;;   "Prevent annoying \"Active processes exist\" query when you quit Emacs."
;;   (flet ((process-list ())) ad-do-it))
(defadvice save-buffers-kill-terminal (before my-save-buffers-kill-terminal activate)
  (when (process-list)
    (dolist (p (process-list))
      (set-process-query-on-exit-flag p nil))))


;; ツールバー非表示
(tool-bar-mode -1)



;; メニューバー非表示
;;; Emacs Mac port版だと仮想デスクトップをスイッチした際に
;;; ウィンドウのフォーカスが外れてしまうため、dawrin以外で実行
;;; OSX: Switching to virtual desktop doesn't focus Emacs
;;; https://emacs.stackexchange.com/questions/28121/osx-switching-to-virtual-desktop-doesnt-focus-emacs
(when (not (equal system-type 'darwin))
  (menu-bar-mode -1))




;; スタートアップを非表示にする
(setq inhibit-startup-screen t)



;; scratchバッファのメッセージを消す
(setq initial-scratch-message "")



;; スクロールを1行ずつにする
(setq scroll-conservatively 35
      scroll-margin 0
      scroll-step 1)



;;ファイル名の補完で大文字小文字の識別をしない
(setq completion-ignore-case t)



;; キャレットが '(' や ')' の直後にある場合に対応する括弧を強調
(show-paren-mode t)



;; Emacs サーバを起動する
;; R だと edit や fix を実行する時に必要
(require 'server)
(unless (server-running-p)
  (server-start))

;; (when (require 'server nil t)
;;   (unless (server-running-p)
;;     (server-start)))



;; 現在行を目立たせる
;; (defface hlline-face
;;   '((((class color)
;;       (background dark))
;;      (:background "#16160e"))
;;     (((class color)
;;       (background light))
;;      (:background "#16160e"))
;;     (t
;;      ()))
;;   "*Face used by hl-line.")
;; (setq hl-line-face 'hlline-face)
(custom-set-faces
'(hl-line ((t (:background "#16160e"))))
)
(global-hl-line-mode)



;; ガベージコレクションの値を設定する
(setq gc-cons-threshold (* 128 1024 1024))



;; ===================================================================

;; 【高速化】Emacsのカーソル移動が重い？
;; http://rubikitch.com/2015/05/14/global-hl-line-mode-timer/

;; ===================================================================

;; タイマー関数を利用して現在行を目立たせる
;; (use-package hl-line
;;   :config

;;   (defun global-hl-line-timer-function ()
;;     (global-hl-line-unhighlight-all)
;;     (let ((global-hl-line-mode t))
;;       (global-hl-line-highlight)))

;;   (setq global-hl-line-timer
;; 	(run-with-idle-timer 0.03 t 'global-hl-line-timer-function)))



;; タイトルバーにファイルのフルパス表示
(setq frame-title-format
      (format "- Emacs@%s - %%f" (system-name)))



;; モードラインに行番号表示
(line-number-mode t)



;; モードラインに列番号表示
(column-number-mode t)



;; カーソルの点滅設定

;; カーソル点滅速度の変更（デフォルトは0.5）
(setq blink-cursor-interval 0.08)
(setq blink-cursor-delay 0.05)
(blink-cursor-mode 1)



;; バッファに変更があったら自動で再読込する
(global-auto-revert-mode 1)



;; abbrevの設定
(setq abbrev-file-name "~/emacs.d/etc/abbrev_defs")


;; ===================================================================

;; 【参考】現在のファイルのパスを取得してクリップボードに保存
;; http://futurismo.biz/archives/2989

;; ===================================================================

;; 現在開いているファイルのパスを保存.
;; dired を開いているときはディレクトリパスを保存.
(defun my/get-curernt-path ()
    (if (equal major-mode 'dired-mode)
    default-directory
    (buffer-file-name)))
 
(defun my/copy-current-path ()                                                         
  (interactive)
  (let ((fPath (my/get-curernt-path)))
    (when fPath
      (message "stored path: %s" fPath)
      (kill-new (file-truename fPath)))))
 
(bind-key "C-c 0" 'my/copy-current-path)



;; ===================================================================

;; 【参考】Emacsでウィンドウのサイズに応じて
;;                           デフォルトの分割方向を決めるようにする
;; http://subtech.g.hatena.ne.jp/y_yanbe/20100615/1276665470

;; ===================================================================

(setq split-width-threshold 90)



;; ===================================================================

;; 【参考】emacsで、全行インデントを一括で行う方法
;; http://qiita.com/AnchorBlues/items/2e216f730c1e9b84a593

;; ===================================================================

(defun all-indent ()
  (interactive)
  (save-excursion
    (indent-region (point-min) (point-max))))

(defun electric-indent ()
  "Indent specified region.
When resion is active, indent region.
Otherwise indent whole buffer."
  (interactive)
  (if (use-region-p)
      (indent-region (region-beginning) (region-end))
    (all-indent)))

(bind-key "C-M-\\" 'electric-indent)



;; ===================================================================

;; 【参考】カーソル位置のURLをブラウザで開く
;; http://tototoshi.hatenablog.com/entry/20100630/1277897703

;; ===================================================================

(defun browse-url-at-point ()
  (interactive)
  (let ((url-region (bounds-of-thing-at-point 'url)))
    (when url-region
      (browse-url (buffer-substring-no-properties (car url-region)
                                                  (cdr url-region))))))
(global-set-key "\C-c\C-o" 'browse-url-at-point)
