;;; early-init.el --- Early initialization for Steel Scheme Emacs -*- lexical-binding: t; -*-

;; 1. Optimize garbage collection threshold during startup (128MB)
(setq gc-cons-threshold (* 128 1024 1024))
(setq gc-cons-percentage 0.6)

;; Restore sane garbage collection threshold after init
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024))
            (setq gc-cons-percentage 0.1)))

;; 2. Suppress unneeded GUI decor early to prevent flickering
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)

(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; 3. Prevent startup messages and scratch buffer noise
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message (user-login-name))
(setq initial-scratch-message ";; 🪓 Steel Scheme & Strict Paredit Hacker Environment\n;; Press Alt+Enter to evaluate expression | Alt+K to expand region\n\n")

(provide 'early-init)
;;; early-init.el ends here
