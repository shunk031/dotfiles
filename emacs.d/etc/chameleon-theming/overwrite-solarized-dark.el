;; overwrite-solarized-dark

;; overwrite settings
(set-face-attribute
   'pyenv-active-python-face nil
   :foreground "white")


;; powerline settings

(setq powerline-color1 "#073642")
(setq powerline-color2 "#002b36")

(set-face-attribute 'mode-line nil
		    :foreground "#fdf6e3"
		    :background "#2aa198"
		    :box nil)
(set-face-attribute 'mode-line-inactive nil
		    :box nil)



;; tabbar settings

(set-face-attribute
 'tabbar-default nil
 :family "Monaco"
 :background "#586e75"
 :foreground "#586e75"
 :box '(:line-width 3 :color "#586e75" :style nil)
 ;; :height 0.8
 )

(set-face-attribute
 'tabbar-unselected nil
 :background "#657b83"
 :foreground "white"
 :box '(:line-width 3 :color "#657b83" :style nil))

(set-face-attribute
 'tabbar-selected nil
 :background "#2aa198"
 :foreground "white"
 :box '(:line-width 3 :color "#2aa198"))

(set-face-attribute
 'tabbar-button nil
 :box nil)

(set-face-attribute
 'tabbar-modified nil
 :background "#657b83"
 :foreground "white"
 :box '(:line-width 3 :color "#657b83"))

(set-face-attribute
 'tabbar-separator nil
 :background "#002b36"
 :foreground "#002b36"
 :box '(:line-width 1 :color "#002b36" :style nil)
 )
