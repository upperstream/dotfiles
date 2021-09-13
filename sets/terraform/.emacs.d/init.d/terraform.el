(use-package terraform-mode)

;;; Comment out the following line to disable auto format feature on
;;; save
(add-hook 'terraform-mode-hook #'terraform-format-on-save-mode)
