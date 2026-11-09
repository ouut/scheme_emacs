;;; ui.el --- UI polish, theme & readability configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Modern aesthetics and essential completion / discovery UI:
;; - Curated high-contrast programming themes (doom-one, doom-gruvbox, doom-tokyo-night, doom-dracula).
;; - Enhanced comment/annotation readability: boosts comment contrast so notes are crisp & legible.
;; - Rainbow Delimiters (color-coded nesting levels).
;; - Which-Key popup for discovering commands and keybindings.
;; - Vertico + Orderless + Marginalia for mini-buffer fuzzy completion.
;; - Corfu for fast, non-intrusive in-buffer completion popup.
;; - Line numbers & clean modeline.

(defgroup steel-ui nil
  "UI and appearance customization for Steel Scheme."
  :group 'steel
  :prefix "steel-")

(defcustom steel-theme 'doom-one
  "Theme to load.
Popular recommendations:
- `doom-gruvbox`: Hacker classic! Warm retro palette, highest comment & AST contrast.
- `doom-one`: Atom One Dark modern classic (with our high-contrast comment boost).
- `doom-tokyo-night`: Cyber-night dark blue aesthetic with vibrant neon highlights.
- `doom-dracula`: High-contrast vampire palette with purple/cyan accents.
- `doom-nord`: Cool arctic blue/grey minimal aesthetic."
  :type 'symbol
  :group 'steel-ui)

;; 1. Theme Configuration & High-Contrast Comment Boost
(when (require 'doom-themes nil t)
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme steel-theme t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config)

  ;; 🌟 Boost Comment Contrast & Readability:
  ;; Default doom-one comment (#5B6268) is too faint. We boost comments to a crisp,
  ;; high-contrast slate-silver (#8e9ea8) with italics across all themes.
  (custom-set-faces
   '(font-lock-comment-face ((t (:foreground "#8e9ea8" :slant italic))))
   '(font-lock-comment-delimiter-face ((t (:foreground "#7b8b94" :slant italic))))
   '(font-lock-doc-face ((t (:foreground "#9ab0ba" :slant italic))))))

;; 2. Rainbow Delimiters (color-coded nesting levels)
(when (require 'rainbow-delimiters nil t)
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

;; 3. Which-Key (instant keybinding cheatsheet on delay)
(when (require 'which-key nil t)
  (setq which-key-idle-delay 0.4)
  (setq which-key-idle-secondary-delay 0.05)
  (which-key-mode 1))

;; 4. Vertico (vertical interactive completion)
(when (require 'vertico nil t)
  (vertico-mode 1)
  (setq vertico-cycle t))

;; 5. Orderless (fuzzy match across spaces)
(when (require 'orderless nil t)
  (setq completion-styles '(orderless basic))
  (setq completion-category-defaults nil)
  (setq completion-category-overrides '((file (styles partial-completion)))))

;; 6. Marginalia (rich annotations for minibuffer items)
(when (require 'marginalia nil t)
  (marginalia-mode 1))

;; 7. Corfu (modern popup completion in buffer)
(when (require 'corfu nil t)
  (setq corfu-auto t)
  (setq corfu-auto-delay 0.15)
  (setq corfu-auto-prefix 2)
  (setq corfu-cycle t)
  (global-corfu-mode 1))

;; 8. Basic Editor Quality of Life
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq standard-indent 2)

;; Line numbers in programming buffers
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Highlight current line
(global-hl-line-mode 1)

;; Column number in mode line
(column-number-mode 1)

(provide 'ui)
;;; ui.el ends here
