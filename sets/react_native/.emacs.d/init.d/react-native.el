(use-package js3-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.js\\'" . js3-mode)))

(use-package flycheck
  :ensure t
  :config
  (add-hook 'after-init-hook #'global-flycheck-mode))

(use-package auto-complete
  :ensure t)

(use-package tern
  :ensure t
  :config
  (autoload 'tern-mode "tern-mode.el" nil t)
  (add-hook 'js-mode-hook (lambda () (tern-mode t))))

(use-package helm-gtags
  :ensure t
  :config
  (add-hook 'js-mode-hook 'helm-gtags-mode))

(use-package tern-auto-complete
  :ensure t)

(eval-after-load 'tern
  '(progn
     (require 'tern-auto-complete)
     (tern-ac-setup)))

(use-package indium
  :ensure t)
