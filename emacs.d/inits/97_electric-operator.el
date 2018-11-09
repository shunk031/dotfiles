(el-get-bundle names)
(use-package names-dev)

(el-get-bundle davidshepherd7/electric-operator)
(use-package electric-operator
  :defer t
  
  :init
  (dolist (hook '(

		  ;;c系modeで利用する
		  c-mode-common-hook

		  ;; python-modeで利用する
		  python-mode-hook

		  ;; ess-modeで利用する
		  ess-mode-hook
		  
		  ;; arduino-modeで利用する
		  arduino-mode-hook

		  ;; perl-modeで利用する
		  perl-mode-hook
		  
		  ))
    (add-hook hook #'electric-operator-mode))
  
  :config
  
  ;; ジェネリクス型を利用する際に無駄なスペースが入ってしまうために
  ;; java-modeでは"<"と">"において動作しないようにした
  (electric-operator-add-rules-for-mode
   'java-mode
   (cons "<" nil)
   (cons ">" nil))

  (electric-operator-add-rules-for-mode
   'php-mode
   (cons "/" nil)
   (cons "<" nil)
   (cons ">" nil)
   (cons "++" "++")
   (cons "//" "// ")
   (cons "." nil)
   (cons "->" "->")
   (cons "=>" " => "))
  
  ;; arduino-modeにelectric-operator-prog-mode-rulesを適応
  (apply #'electric-operator-add-rules-for-mode 'arduino-mode
	 electric-operator-prog-mode-rules)
  
  )
