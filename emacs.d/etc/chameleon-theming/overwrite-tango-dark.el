;; overwrite-tango-dark

;; Change the rate of permeability of the window
(if window-system
    (progn
      (set-background-color "Black")
      (set-foreground-color "LightGray")
      (set-frame-parameter nil 'alpha 80)
      ))

;; Change pyenv-active-python-face color
(set-face-attribute
 'pyenv-active-python-face nil
 :foreground "#006400")

;; powerline
;; クリスマス仕様
(set-face-background 'mode-line         "#FF0000")   ; red
(set-face-foreground 'mode-line         "#FFFFDC")   ; near-white
(set-face-background 'powerline-active1 "#006400")   ; dark green
(set-face-foreground 'powerline-active1 "#FFD700")   ; gold
(set-face-background 'powerline-active2 "#FFFFDC")   ; near-white
(set-face-foreground 'powerline-active2 "#FFFFDC")   ; near-black


;; tabbar
;; クリスマス仕様
(set-face-attribute
 'tabbar-default nil
 :family "Monaco"
 :background "#006400"
 :foreground "#006400"
 :box '(:line-width 3 :color "#006400" :style nil)
 ;; :height 0.8
 )

(set-face-attribute
 'tabbar-unselected nil
 :background "white"
 :foreground "#006400"
 :box '(:line-width 3 :color "white" :style nil))

(set-face-attribute
 'tabbar-selected nil
 :background "#FF0000"
 :foreground "white"
 :box '(:line-width 3 :color "#FF0000"))

(set-face-attribute
 'tabbar-button nil
 :box nil)

(set-face-attribute
 'tabbar-modified nil
 :background "white"
 :foreground "#F1266F"
 :box '(:line-width 3 :color "white"))

(set-face-attribute
 'tabbar-separator nil
 :background "#FFD700"
 :foreground "#FFD700"
 :box '(:line-width 1 :color "#FFD700" :style nil)
 )
