;;; test_zig_emacs.el --- Tests for Zig dotfiles -*- lexical-binding: t; -*-

;; Provided under the ISC License.  See LICENSE.txt file for details.

(require 'ert)
(require 'package)
(package-initialize)
(require 'use-package)

(defconst dotfiles-zig-emacs-config
  (expand-file-name
   "../sets/zig/.emacs.d/init.d/zig.el"
   (file-name-directory load-file-name)))

(ert-deftest dotfiles-zig-source-mode ()
  (should (file-readable-p dotfiles-zig-emacs-config))
  (let ((auto-mode-alist nil))
    (load dotfiles-zig-emacs-config nil t)
    (with-temp-buffer
      (setq buffer-file-name "example.zig")
      (set-auto-mode)
      (should (eq major-mode 'zig-mode))
      (should-not indent-tabs-mode))))

(ert-deftest dotfiles-zig-zon-mode ()
  (let ((auto-mode-alist nil))
    (load dotfiles-zig-emacs-config nil t)
    (with-temp-buffer
      (setq buffer-file-name "build.zig.zon")
      (set-auto-mode)
      (should (eq major-mode 'zig-mode)))))

(ert-deftest dotfiles-zig-format-on-save ()
  (skip-unless (executable-find "zig"))
  (load dotfiles-zig-emacs-config nil t)
  (let ((file (make-temp-file "dotfiles-zig-" nil ".zig"))
        (make-backup-files nil))
    (unwind-protect
        (progn
          (with-temp-buffer
            (setq buffer-file-name file)
            (set-auto-mode)
            (should (bound-and-true-p zig-format-on-save-mode))
            (insert "pub fn main() void{ }\n")
            (save-buffer))
          (with-temp-buffer
            (insert-file-contents file)
            (should (equal (buffer-string)
                           "pub fn main() void {}\n"))))
      (delete-file file))))

(ert-deftest dotfiles-zig-does-not-affect-text-mode ()
  (load dotfiles-zig-emacs-config nil t)
  (with-temp-buffer
    (setq buffer-file-name "notes.txt")
    (set-auto-mode)
    (should (eq major-mode 'text-mode))
    (should-not (bound-and-true-p zig-format-on-save-mode))))

;;; test_zig_emacs.el ends here
