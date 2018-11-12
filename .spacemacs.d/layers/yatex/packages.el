;;; packages.el --- yatex layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2017 Sylvain Benner & Contributors
;;
;; Author: Shunsuke KITADA <shunk031@OguraYuiMacbook.local>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `yatex-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `yatex/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `yatex/pre-init-PACKAGE' and/or
;;   `yatex/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst yatex-packages
  '(
    yatex
    (popwin-yatex :location (recipe :fetcher github
                                    :repo "m2ym/popwin-el"
                                    :files ("misc/popwin-yatex.el")))
    )
  "The list of Lisp packages required by the yatex layer.

Each entry is either:

1. A symbol, which is interpreted as a package to be installed, or

2. A list of the form (PACKAGE KEYS...), where PACKAGE is the
    name of the package to be installed or loaded, and KEYS are
    any number of keyword-value-pairs.

    The following keys are accepted:

    - :excluded (t or nil): Prevent the package from being loaded
      if value is non-nil

    - :location: Specify a custom installation location.
      The following values are legal:

      - The symbol `elpa' (default) means PACKAGE will be
        installed using the Emacs package manager.

      - The symbol `local' directs Spacemacs to load the file at
        `./local/PACKAGE/PACKAGE.el'

      - A list beginning with the symbol `recipe' is a melpa
        recipe.  See: https://github.com/milkypostman/melpa#recipe-format")

(defun yatex/init-yatex ()
  (use-package yatex
    :defer t
    :commands (popwin)
    :mode
    (("\\.tex$" . yatex-mode)
	   ("\\.ltx$" . yatex-mode)
	   ("\\.cls$" . yatex-mode)
	   ("\\.sty$" . yatex-mode)
	   ("\\.clo$" . yatex-mode)
	   ("\\.bbl$" . yatex-mode))
    :config
    (progn
      (global-set-key (kbd "C-c g t") 'google-translate-enja-or-jaen)
      
      (setq YaTeX-inhibit-prefix-letter t)
      (setq YaTeX-kanji-code nil)
      (setq YaTeX-use-LaTeX2e t)
      (setq YaTeX-use-AMS-LaTeX t)
      (setq YaTeX-dvi2-command-ext-alist
	          '(("Preview\\|TeXShop\\|TeXworks\\|Skim\\|mupdf\\|xpdf\\|Firefox\\|Adobe" . ".pdf")))

      (when (eq system-type 'darwin)
        (setq tex-command "/Library/TeX/texbin/ptex2pdf -l -ot '-synctex=1'")
        (setq bibtex-command (cond ((string-match "uplatex\\|-u" tex-command) "/usr/texbin/upbibtex")
			                             ((string-match "platex" tex-command) "/usr/texbin/pbibtex")
			                             ((string-match "lualatex\\|luajitlatex\\|xelatex" tex-command) "/usr/texbin/bibtexu")
			                             ((string-match "pdflatex\\|latex" tex-command) "/usr/texbin/bibtex")
			                             (t "/usr/texbin/pbibtex")))

        (setq dvi2-command "/usr/bin/open -a Skim")
        (setq dviprint-command-format "/usr/bin/open -a \"Adobe Reader\" `echo %s | sed -e \"s/\\.[^.]*$/\\.pdf/\"`")
        )
      (when (eq system-type 'gnu/linux)
        (setq tex-command "platex")
        (setq bibtex-command "pbibtex")
        (setq dvi2-command "xdvi")
        (setq dviprint-command-format "dvipdfmx"))
      )

    (setq YaTeX-latex-message-code 'utf-8)

    (defun skim-forward-search ()
      (interactive)
      (progn
        (process-kill-without-query
         (start-process
	        "displayline"
	        nil
	        "/Applications/Skim.app/Contents/SharedSupport/displayline"
	        (number-to-string (save-restriction
			                        (widen)
			                        (count-lines (point-min) (point))))
	        (expand-file-name
	         (concat (file-name-sans-extension (or YaTeX-parent-file
					                                       (save-excursion
						                                       (YaTeX-visit-main t)
						                                       buffer-file-name)))
		               ".pdf"))
	        buffer-file-name))))

    ;; 自動で改行しないようにする
    (auto-fill-mode -1)

    (setq YaTeX-use-hilit19 nil)
    ))

;; (defun yatex/init-popwin-yatex ()
;;   (use-package popwin-yatex
;;     :after (yatex popwin)
;;     :commands (yatex popwin)
;;     :config
;;     (progn
;;       (push '("*dvi-preview*" :height 10) popwin:special-display-config)
;;       (push '("*YaTeX-typesetting*") popwin:special-display-config)
;;       )
;;     )
;;   )

;;; packages.el ends here
