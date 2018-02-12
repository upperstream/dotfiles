(use-package yasnippet
  :ensure t
  :pin melpa-stable)

(use-package meghanada
  :ensure t
  :pin melpa-stable)

(add-hook 'java-mode-hook
	  (lambda ()
	    ;; meghanada-mode on
	    (meghanada-mode t)
	    (setq c-basic-offset 2)
	    ;; use code format
	    (add-hook 'before-save-hook 'meghanada-code-beautify-before-save)))

(use-package auto-complete
  :ensure t
  :pin melpa-stable)

(add-to-list 'load-path "~/.emacs.d/auto-java-complete/")
(require 'ajc-java-complete-config)
(add-hook 'java-mode-hook 'ajc-java-complete-mode)
(add-hook 'find-file-hook 'ajc-4-jsp-find-file-hook)

(use-package java-snippets
  :ensure t)
