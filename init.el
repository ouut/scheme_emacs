;;; init.el --- Master Emacs Configuration for Steel Scheme & Strict Paredit -*- lexical-binding: t; -*-

;;; ============================================================================
;;; 1. Environment & PATH Discovery (Portable bin, Cargo, Steel)
;;; ============================================================================

(let* ((init-dir (file-name-directory (or load-file-name buffer-file-name user-init-file)))
       (portable-bin (expand-file-name "bin" init-dir))
       (parent-bin (expand-file-name "../bin" init-dir))
       (cargo-bin (expand-file-name "~/.cargo/bin")))
  (dolist (dir (list portable-bin parent-bin cargo-bin))
    (when (file-directory-p dir)
      (add-to-list 'exec-path dir)
      (setenv "PATH" (concat dir path-separator (getenv "PATH"))))))

;; Windows (w32 / windows-nt) modifier keys & menu bar configuration
(when (or (eq system-type 'windows-nt) (eq window-system 'w32))
  (setq w32-pass-alt-to-system nil)       ; Stop Alt key from opening/activating Windows menu bar
  (setq w32-alt-is-meta t)                ; Treat Alt key as Meta modifier
  (setq w32-pass-lwindow-to-system nil)   ; Emacs captures Left Windows key
  (setq w32-lwindow-modifier 'super)      ; Left Win key acts as Super
  (setq w32-pass-rwindow-to-system nil)   ; Emacs captures Right Windows key
  (setq w32-rwindow-modifier 'super)      ; Right Win key acts as Super
  (setq w32-apps-modifier 'hyper))        ; Menu/App key acts as Hyper

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

;; Ensure *scratch* buffer defaults to scheme-mode
(when (get-buffer "*scratch*")
  (with-current-buffer "*scratch*"
    (when (memq major-mode '(lisp-interaction-mode fundamental-mode))
      (scheme-mode))))

(add-hook 'emacs-startup-hook
          (lambda ()
            (when (get-buffer "*scratch*")
              (with-current-buffer "*scratch*"
                (when (memq major-mode '(lisp-interaction-mode fundamental-mode))
                  (scheme-mode))))))

;;; ============================================================================
;;; 4. Default Custom File (Keep init.el clean)
;;; ============================================================================

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file t))

(message "🚀 Steel Scheme & Strict Paredit Environment Loaded! Press Alt+Enter to eval, M-x run-steel for REPL.")

(provide 'init)
;;; init.el ends here
