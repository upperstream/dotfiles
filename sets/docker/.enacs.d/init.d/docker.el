(use-package docker
  :ensure t
  :bind ("C-c d" . docker))

(use-package dockerfile-mode
  :ensure t)
(add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode))

(use-package docker-compose-mode)

(use-package docker-tramp)

(add-to-list 'tramp-remote-path 'tramp-own-remote-path)
