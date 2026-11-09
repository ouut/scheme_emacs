;;; init.el --- Master Emacs Configuration for Steel Scheme & Strict Paredit -*- lexical-binding: t; -*-

;;; ============================================================================
;;; 1. Environment & PATH Discovery (Cargo / Steel)
;;; ============================================================================

(let ((cargo-bin (expand-file-name "~/.cargo/bin")))
  (when (file-directory-p cargo-bin)
    (add-to-list 'exec-path cargo-bin)
    (setenv "PATH" (concat cargo-bin ":" (getenv "PATH")))))

;; macOS Option key configuration (removes dead key conflicts)
(when (memq window-system '(mac ns pgtk))
  (setq mac-option-modifier 'meta)
  (setq ns-option-modifier 'meta)
  (setq mac-right-option-modifier 'meta)
  (setq ns-right-option-modifier 'meta)
  (setq mac-command-modifier 'super)
  (setq ns-command-modifier 'super))

;; Add our lisp directory to load-path
(let ((lisp-dir (expand-file-name "lisp" (file-name-directory (or load-file-name buffer-file-name user-init-file)))))
  (add-to-list 'load-path lisp-dir))

;;; ============================================================================
;;; 2. Package Management & Auto Installation
;;; ============================================================================

(require 'package)
(setq package-check-signature nil)  ;; Avoid GPG signature failure on clean environments (Windows/CI)
(setq package-archives '(("melpa"  . "https://melpa.org/packages/")
                         ("gnu"    . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
(package-initialize)

(defvar required-packages
  '(paredit
    expand-region
    rainbow-delimiters
    doom-themes
    which-key
    vertico
    orderless
    marginalia
    corfu))

;; Auto install any missing packages
(let ((need-refresh nil))
  (dolist (pkg required-packages)
    (unless (package-installed-p pkg)
      (unless need-refresh
        (ignore-errors (package-refresh-contents))
        (setq need-refresh t))
      (condition-case err
          (package-install pkg)
        (error
         (message "Warning: Could not install package %s: %s" pkg (error-message-string err)))))))

;;; ============================================================================
;;; 3. Load Modules
;;; ============================================================================

(require 'strict-paredit)
(require 'steel-scheme)
(require 'ui)

;;; ============================================================================
;;; 4. Default Custom File (Keep init.el clean)
;;; ============================================================================

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file t))

(message "🚀 Steel Scheme & Strict Paredit Environment Loaded! Press Alt+Enter to eval, M-x run-steel for REPL.")

(provide 'init)
;;; init.el ends here
