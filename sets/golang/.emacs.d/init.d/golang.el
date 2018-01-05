(exec-path-from-shell-copy-env "GOPATH")

(use-package go-mode
  :ensure t
  :pin melpa-stable)

(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

(use-package flymake-go
  :ensure t)

(eval-after-load "go-mode"
  '(require 'flymake-go))

(use-package auto-complete
  :ensure t
  :pin melpa-stable)

(use-package go-autocomplete
  :ensure t
  :pin melpa-stable)

(require 'go-autocomplete)
(require 'auto-complete-config)
(ac-config-default)
