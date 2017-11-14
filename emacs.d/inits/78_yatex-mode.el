;;
;; setting for yatex-mode.el
;;

;; =========================================================

;; 【参考】TeX環境構築： Emacs+YaTeX+RefTeX
;; http://keisanbutsuriya.hateblo.jp/entry/2015/03/13/175219

;; =========================================================

;; =========================================================

;; 【参考】TeXLive2013 +Emacs + YaTex の設定をした
;; http://tnil.hatenadiary.jp/entry/20130823/1377230350

;; =========================================================
(el-get-bundle elpa:yatex)

(use-package yatex
  :defer t
  :mode (("\\.tex$" . yatex-mode)
	 ("\\.ltx$" . yatex-mode)
	 ("\\.cls$" . yatex-mode)
	 ("\\.sty$" . yatex-mode)
	 ("\\.clo$" . yatex-mode)
	 ("\\.bbl$" . yatex-mode))
  :config
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
  
  )
