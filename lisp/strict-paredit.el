;;; strict-paredit.el --- Strict Paredit H-J-K-L + W/S System -*- lexical-binding: t; -*-

;;; Commentary:
;; Implements the "Strict Paredit Mindset":
;; 1. The parenthesis structure is sacred and always balanced.
;; 2. Never manually insert/delete unbalanced single parentheses.
;; 3. Right-hand H-J-K-L Four-Axis Eight-State Matrix + W/S Depth Traversal:
;;    - H: Wrap Parens (Alt+H -> '()') / Wrap Square (Alt+Shift+H -> '[]')
;;    - J: Barf Left (Alt+J -> pull paren left, kick last item out) / Split (Alt+Shift+J)
;;    - K: Vertical Breathing (Alt+K -> Expand region / Alt+Shift+K -> Contract region)
;;    - L: Slurp Right (Alt+L -> pull paren right, swallow item) / Transpose (Alt+Shift+L)
;;    - W: Step Into (Alt+W -> dive down into inner parenthesis)
;;    - S: Step Out (Alt+S -> jump back up to parent parenthesis)
;;    - O: Splice / Unwrap (Alt+O -> dissolve outer parenthesis shell)
;;    - 1 / 2: Backward / Forward Sexp (Alt+1 / Alt+2)
;;    - 3: Mark Defun / Top-level form (Alt+3)
;;    - \: Reindent Defun / Region DWIM (Alt+\)

(require 'paredit)
(require 'expand-region)

;;; ============================================================================
;;; Helper Commands
;;; ============================================================================

(defun strict-paredit-transpose-dwim ()
  "Transpose adjacent sexps cleanly (Alt + Shift + L).
If point is at the beginning of a sexp, moves forward first to swap with the next."
  (interactive)
  (condition-case nil
      (if (and (looking-at "[^][ \t\n(){}]+")
               (not (looking-back "[^][ \t\n(){}]+" (max (point-min) (- (point) 1)))))
          (progn
            (forward-sexp 1)
            (transpose-sexps 1))
        (transpose-sexps 1))
    (error (message "Cannot transpose sexps here"))))

(defun strict-paredit-splice-dwim ()
  "Splice / unwrap current sexp shell (Alt + O).
If point is on or immediately outside an opening/closing delimiter, steps inside first."
  (interactive)
  (condition-case nil
      (progn
        (cond
         ((memq (char-after) '(?\( ?\[ ?\{))
          (forward-char 1))
         ((memq (char-before) '(?\) ?\] ?\}))
          (backward-char 1)))
        (paredit-splice-sexp))
    (error (message "Can't splice here"))))

(defun strict-paredit-step-into ()
  "Step into the inner sexp (Alt + W).
Directly moves point inside the next/current parenthesis."
  (interactive)
  (condition-case nil
      (paredit-forward-down)
    (error
     (condition-case nil
         (down-list 1)
       (error (message "Already at deepest sexp level"))))))

(defun strict-paredit-step-out ()
  "Step out to parent sexp (Alt + S).
Directly jumps back to the enclosing parenthesis start."
  (interactive)
  (condition-case nil
      (paredit-backward-up)
    (error
     (condition-case nil
         (backward-up-list 1)
       (error (message "Already at top-level sexp"))))))

(defun strict-paredit-indent-dwim ()
  "Reindent current defun or active region cleanly (Alt + \\)."
  (interactive)
  (if (use-region-p)
      (progn
        (indent-region (region-beginning) (region-end))
        (message "Region indented"))
    (condition-case nil
        (progn
          (paredit-reindent-defun)
          (message "Defun reindented"))
      (error
       (save-excursion
         (beginning-of-defun)
         (let ((start (point)))
           (end-of-defun)
           (indent-region start (point))))
       (message "Form reindented")))))

(defun strict-paredit-kill-sexp-dwim ()
  "Kill the next sexp forward without breaking structural integrity."
  (interactive)
  (condition-case nil
      (kill-sexp 1)
    (error (message "No sexp ahead to kill"))))

;;; ============================================================================
;;; Keybindings Configuration
;;; ============================================================================

(defvar strict-paredit-bindings
  '(;; --- 1. H Axis: Hold / Hug (Wrap) ---
    ("M-h"     . paredit-wrap-round)               ; Alt + H: Wrap with (...)
    ("M-H"     . paredit-wrap-square)              ; Alt + Shift + H: Wrap with [...]
    ("M-S-h"   . paredit-wrap-square)
    ("s-h"     . paredit-wrap-round)               ; Super/Win/Cmd + H
    ("s-H"     . paredit-wrap-square)
    ("s-S-h"   . paredit-wrap-square)

    ;; --- 2. J Axis: Barf & Split ---
    ("M-j"     . paredit-forward-barf-sexp)        ; Alt + J: Left Barf (kick last out)
    ("M-J"     . paredit-split-sexp)               ; Alt + Shift + J: Split list at point
    ("M-S-j"   . paredit-split-sexp)
    ("s-j"     . paredit-forward-barf-sexp)
    ("s-J"     . paredit-split-sexp)
    ("s-S-j"   . paredit-split-sexp)

    ;; --- 3. K Axis: Vertical Breathing (Expand / Contract) ---
    ("M-k"     . er/expand-region)                 ; Alt + K: Expand selection
    ("M-K"     . er/contract-region)               ; Alt + Shift + K: Contract selection
    ("M-S-k"   . er/contract-region)
    ("s-k"     . er/expand-region)
    ("s-K"     . er/contract-region)
    ("s-S-k"   . er/contract-region)

    ;; --- 4. L Axis: Slurp & Transpose ---
    ("M-l"     . paredit-forward-slurp-sexp)       ; Alt + L: Right Slurp (pull in)
    ("M-L"     . strict-paredit-transpose-dwim)    ; Alt + Shift + L: Transpose adjacent
    ("M-S-l"   . strict-paredit-transpose-dwim)
    ("s-l"     . paredit-forward-slurp-sexp)
    ("s-L"     . strict-paredit-transpose-dwim)
    ("s-S-l"   . strict-paredit-transpose-dwim)

    ;; --- 5. W / S Depth Traversal ---
    ("M-w"     . strict-paredit-step-into)         ; Alt + W: Step into (钻入)
    ("M-s"     . strict-paredit-step-out)          ; Alt + S: Step out (跳出)
    ("s-w"     . strict-paredit-step-into)
    ("s-s"     . strict-paredit-step-out)

    ;; --- 6. O Axis: Splice / Unwrap ---
    ("M-o"     . strict-paredit-splice-dwim)       ; Alt + O: Splice shell
    ("s-o"     . strict-paredit-splice-dwim)

    ;; --- 7. Fast Navigation & Selection (1, 2, 3) ---
    ("M-1"     . paredit-backward)                 ; Alt + 1: Step backward sexp
    ("M-2"     . paredit-forward)                  ; Alt + 2: Step forward sexp
    ("M-3"     . mark-defun)                       ; Alt + 3: Select top-level defun
    ("s-1"     . paredit-backward)
    ("s-2"     . paredit-forward)
    ("s-3"     . mark-defun)

    ;; --- 8. Reindent & Kill Sexp ---
    ("M-\\"    . strict-paredit-indent-dwim)       ; Alt + \: Smart indent
    ("s-\\"    . strict-paredit-indent-dwim)
    ("M-X"     . strict-paredit-kill-sexp-dwim)    ; Alt + Shift + X: Kill sexp
    ("M-S-x"   . strict-paredit-kill-sexp-dwim)
    ("s-X"     . strict-paredit-kill-sexp-dwim)
    ("s-S-x"   . strict-paredit-kill-sexp-dwim)
    ("C-M-k"   . strict-paredit-kill-sexp-dwim)    ; Standard Emacs kill-sexp
    ))

(defun strict-paredit-apply-keys (keymap)
  "Apply the strict paredit keybindings into KEYMAP."
  (dolist (binding strict-paredit-bindings)
    (define-key keymap (kbd (car binding)) (cdr binding))))

;; Apply to paredit-mode-map
(with-eval-after-load 'paredit
  (strict-paredit-apply-keys paredit-mode-map))

;;; ============================================================================
;;; Strict Paredit Minor Mode Setup
;;; ============================================================================

(defun strict-paredit-enable ()
  "Enable strict paredit and related aids."
  (paredit-mode 1)
  (show-paren-mode 1)
  (setq-local show-paren-delay 0)
  (setq-local show-paren-style 'parenthesis)
  (when (fboundp 'rainbow-delimiters-mode)
    (rainbow-delimiters-mode 1)))

;; Hook into all Lisp/Scheme editing modes
(add-hook 'scheme-mode-hook #'strict-paredit-enable)
(add-hook 'lisp-mode-hook #'strict-paredit-enable)
(add-hook 'emacs-lisp-mode-hook #'strict-paredit-enable)
(add-hook 'lisp-interaction-mode-hook #'strict-paredit-enable)

(provide 'strict-paredit)
;;; strict-paredit.el ends here
