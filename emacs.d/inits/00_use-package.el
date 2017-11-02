;;
;;; setting for use-package.el
;;

(el-get-bundle use-package)

;; use-package が存在しないときは何もしないようにする
(unless (require 'use-package nil t)
  (defmacro use-package (&rest args)))

(require 'bind-key)
