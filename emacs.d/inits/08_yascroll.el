(el-get-bundle yascroll)
(use-package yascroll
  :defer t
  :init
  ;; まずは標準のスクロールバーを消す
  (scroll-bar-mode 0)
  
  :config
  (global-yascroll-bar-mode t))
