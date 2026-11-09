;;; steel-scheme.el --- Rust Steel Scheme Integration for Emacs -*- lexical-binding: t; -*-

;;; Commentary:
;; Integrates the Rust Steel Scheme interpreter (https://github.com/mattwparas/steel)
;; with Emacs scheme-mode:
;; - Automatic discovery of the `steel` executable.
;; - Full interactive REPL (`run-steel`, `steel-repl`) with smart 60:40 split.
;; - One-shot evaluation (`Alt + Enter` / `Ctrl + Enter` / `C-c C-c`):
;;   Evaluates active region, innermost enclosing S-expression, or defun.
;; - Momentary pulse highlight on evaluated code for instant visual feedback.
;; - Intelligent prompt de-duplication:
;;   Cleans comments & empty lines before pipe transmission and collapses
;;   redundant consecutive `λ >` prompt artifacts.
;; - Seamless REPL management:
;;   - `C-c C-q`: Hide/close REPL window (keeps background process alive)
;;   - `C-c C-z`: Smart toggle (open -> focus -> hide back to editor)
;;   - `C-c C-d`: Kill REPL process completely and close window
;;   - Standard Emacs: `C-x 1` in editor (expand full screen), `C-x 0` in REPL (close window)
;; - Steel-specific syntax highlighting, keywords, and indentation rules.
;; - Prettify symbols (lambda/fn -> λ).
;; - Strict paredit integration in both Scheme files and REPL buffer.

(require 'scheme)
(require 'cmuscheme)
(require 'pulse)
(require 'cl-lib)
(require 'subr-x)
(require 'strict-paredit)

;;; ============================================================================
;;; Customization & Executable Discovery
;;; ============================================================================

(defgroup steel nil
  "Rust Steel Scheme development environment."
  :group 'scheme
  :prefix "steel-")

(defcustom steel-program-name
  (or (executable-find "steel")
      (let ((cargo-steel (expand-file-name "~/.cargo/bin/steel")))
        (when (file-executable-p cargo-steel) cargo-steel))
      "steel")
  "Path to the Rust Steel Scheme executable."
  :type 'string
  :group 'steel)

(defcustom steel-repl-buffer-name "*steel-repl*"
  "Name of the Steel Scheme REPL buffer."
  :type 'string
  :group 'steel)

(defcustom steel-split-ratio 0.6
  "Default window split ratio for editor : REPL (0.6 = 60:40)."
  :type 'float
  :group 'steel)

;;; ============================================================================
;;; REPL Buffer & Process Management
;;; ============================================================================

(defun steel-proc ()
  "Return the live Steel process, or nil if not running."
  (let ((proc (get-buffer-process steel-repl-buffer-name)))
    (and (processp proc)
         (process-live-p proc)
         proc)))

(defun steel-display-repl-window (&optional select)
  "Display the Steel REPL buffer in a side or bottom window.
Uses a 60:40 horizontal split on wide screens, or 70:30 on narrow screens.
If SELECT is non-nil, switch focus to the REPL window."
  (let* ((buf (get-buffer steel-repl-buffer-name))
         (win (and buf (get-buffer-window buf))))
    (unless (or win (not (buffer-live-p buf)))
      (if (> (window-total-width) 120)
          ;; Wide screen: right split (60 : 40)
          (setq win (split-window-right (floor (* (window-total-width) steel-split-ratio))))
        ;; Narrow screen: bottom split (70 : 30)
        (setq win (split-window-below (floor (* (window-total-height) 0.7)))))
      (set-window-buffer win buf))
    (when (and select win)
      (select-window win))
    win))

(defun steel-scroll-repl-to-bottom ()
  "Scroll the Steel REPL window to the bottom if visible."
  (let* ((buf (get-buffer steel-repl-buffer-name))
         (win (and buf (get-buffer-window buf))))
    (when (and buf win)
      (with-selected-window win
        (goto-char (point-max))))))

(defun steel--collapse-consecutive-prompts (_output)
  "Collapse repeated `λ >` prompts on the same line in REPL output."
  (save-excursion
    (let ((inhibit-read-only t))
      (goto-char (max (point-min) (- (point-max) 500)))
      (while (re-search-forward "λ > \\(λ > \\)+" nil t)
        (replace-match "λ > ")))))

;;;###autoload
(defun run-steel (&optional select)
  "Start or switch to the interactive Steel Scheme REPL.
If SELECT is non-nil, focus the REPL window.
Configures strict paredit and rainbow delimiters inside the REPL."
  (interactive "p")
  (let ((proc (steel-proc)))
    (unless proc
      (unless (executable-find steel-program-name)
        (error "Steel binary not found at '%s'. Check your PATH or `steel-program-name`"
               steel-program-name))
      ;; Set cmuscheme program name
      (setq scheme-program-name steel-program-name)
      ;; Create comint buffer for steel
      (let ((buf (make-comint-in-buffer
                  "steel-repl"
                  steel-repl-buffer-name
                  steel-program-name
                  nil)))
        (with-current-buffer buf
          (inferior-scheme-mode)
          ;; Enable Strict Paredit inside the REPL
          (strict-paredit-enable)
          ;; Comint settings
          (setq-local comint-prompt-regexp "^[λ> ]* ")
          (setq-local comint-scroll-to-bottom-on-output t)
          (setq-local comint-move-point-for-output t)
          ;; Output filter to remove prompt spam
          (add-hook 'comint-output-filter-functions #'steel--collapse-consecutive-prompts nil t)
          ;; Bind close keys in REPL buffer as well
          (local-set-key (kbd "C-c C-q") #'steel-hide-repl)
          (local-set-key (kbd "C-c C-z") #'steel-toggle-repl)
          (local-set-key (kbd "C-c C-d") #'steel-kill-repl))))
    (steel-display-repl-window select)
    (steel-scroll-repl-to-bottom)
    (steel-proc)))

;; Alias for convenience
(defalias 'steel-repl 'run-steel)

;;;###autoload
(defun steel-hide-repl ()
  "Close/hide the Steel REPL window without killing the process (C-c C-q).
The background Steel session and defined functions remain intact."
  (interactive)
  (let* ((buf (get-buffer steel-repl-buffer-name))
         (win (and buf (get-buffer-window buf))))
    (if win
        (progn
          (delete-window win)
          (message "Steel REPL window closed (process still running in background)."))
      (message "Steel REPL window is not visible."))))

;;;###autoload
(defun steel-toggle-repl ()
  "Smart toggle the Steel REPL window (C-c C-z).
- If inside REPL window: close it and return focus to editor.
- If in editor and REPL window is visible: switch focus to REPL.
- If REPL window is hidden: open it and focus."
  (interactive)
  (let* ((buf (get-buffer steel-repl-buffer-name))
         (win (and buf (get-buffer-window buf))))
    (cond
     ;; If currently inside the REPL window -> close window and return
     ((and win (eq (selected-window) win))
      (delete-window win)
      (message "Steel REPL window closed."))
     ;; If REPL window is visible -> focus it
     (win
      (select-window win))
     ;; If REPL window is not visible -> open and focus
     (t
      (run-steel t)))))

;;;###autoload
(defalias 'steel-switch-to-repl 'steel-toggle-repl)

;;;###autoload
(defun steel-kill-repl ()
  "Kill the Steel REPL process completely and close its window (C-c C-d)."
  (interactive)
  (let* ((proc (steel-proc))
         (buf (get-buffer steel-repl-buffer-name))
         (win (and buf (get-buffer-window buf))))
    (when win
      (delete-window win))
    (when proc
      (delete-process proc))
    (when buf
      (kill-buffer buf))
    (message "Steel REPL terminated.")))

;;; ============================================================================
;;; Code Evaluation DWIM & Commands
;;; ============================================================================

(defun steel--clean-code-string (str)
  "Filter out pure comment lines and collapse empty lines from STR before sending to Steel."
  (let* ((lines (split-string str "\n"))
         (cleaned (cl-remove-if
                   (lambda (line)
                     (let ((trimmed (string-trim line)))
                       (or (string-empty-p trimmed)
                           (string-prefix-p ";" trimmed))))
                   lines)))
    (if cleaned
        (string-join cleaned "\n")
      "")))

(defun steel--innermost-sexp-bounds ()
  "Return (START . END) of the innermost enclosing S-expression at point."
  (save-excursion
    (condition-case nil
        (cond
         ;; 1. Looking at an opening parenthesis
         ((memq (char-after) '(?\( ?\[ ?\{))
          (let ((start (point)))
            (forward-sexp 1)
            (cons start (point))))

         ;; 2. Right after a closing parenthesis
         ((memq (char-before) '(?\) ?\] ?\}))
          (let ((end (point)))
            (backward-sexp 1)
            (cons (point) end)))

         ;; 3. Inside a parenthesized list -> climb out to enclosing list
         (t
          (backward-up-list 1)
          (let ((start (point)))
            (forward-sexp 1)
            (cons start (point)))))
      (error
       ;; 4. Fallback: current symbol or defun
       (condition-case nil
           (let ((b (bounds-of-thing-at-point 'sexp)))
             (or b
                 (progn
                   (beginning-of-defun)
                   (let ((s (point)))
                     (end-of-defun)
                     (cons s (point))))))
         (error (cons (point-min) (point-max))))))))

(defun steel-send-string (str)
  "Send STR directly to the live Steel REPL process.
Pre-cleans unnecessary blank/comment lines to prevent prompt accumulation."
  (let ((proc (or (steel-proc) (run-steel nil)))
        (cleaned (steel--clean-code-string str)))
    (when (and cleaned (not (string-empty-p cleaned)))
      (unless (string-suffix-p "\n" cleaned)
        (setq cleaned (concat cleaned "\n")))
      (comint-send-string proc cleaned)
      (steel-scroll-repl-to-bottom))))

;;;###autoload
(defun steel-eval-dwim ()
  "One-shot evaluation DWIM (Alt + Enter / Ctrl + Enter).
1. If region is active: evaluate active region.
2. If cursor is at or inside an S-expression: evaluate innermost enclosing sexp.
3. Momentarily pulse-highlights the evaluated code and scrolls REPL."
  (interactive)
  (let (start end code)
    (cond
     ;; 1. Active region
     ((use-region-p)
      (setq start (region-beginning)
            end (region-end)))

     ;; 2. Innermost S-expression
     (t
      (let ((bounds (steel--innermost-sexp-bounds)))
        (setq start (car bounds)
              end (cdr bounds)))))

    (when (and start end (< start end))
      (setq code (buffer-substring-no-properties start end))
      ;; Visual flash feedback
      (when (fboundp 'pulse-momentary-highlight-region)
        (pulse-momentary-highlight-region start end 'highlight))
      ;; Send to Steel REPL
      (steel-send-string code)
      (message "λ => Sent to Steel REPL: %s"
               (truncate-string-to-width
                (replace-regexp-in-string "[\n\t ]+" " " (string-trim code))
                50 0 nil "...")))))

;;;###autoload
(defun steel-send-definition ()
  "Send current top-level definition to Steel REPL (C-c C-c / C-M-x)."
  (interactive)
  (save-excursion
    (beginning-of-defun)
    (let ((start (point)))
      (end-of-defun)
      (let ((end (point)))
        (when (fboundp 'pulse-momentary-highlight-region)
          (pulse-momentary-highlight-region start end 'highlight))
        (steel-send-string (buffer-substring-no-properties start end))
        (message "λ => Evaluated definition")))))

;;;###autoload
(defun steel-send-buffer ()
  "Send the entire buffer to Steel REPL (C-c C-b)."
  (interactive)
  (when (fboundp 'pulse-momentary-highlight-region)
    (pulse-momentary-highlight-region (point-min) (point-max) 'highlight))
  (steel-send-string (buffer-substring-no-properties (point-min) (point-max)))
  (message "λ => Buffer sent to Steel REPL"))

;;;###autoload
(defun steel-send-region (start end)
  "Send selected region from START to END to Steel REPL (C-c C-r)."
  (interactive "r")
  (when (fboundp 'pulse-momentary-highlight-region)
    (pulse-momentary-highlight-region start end 'highlight))
  (steel-send-string (buffer-substring-no-properties start end))
  (message "λ => Region sent to Steel REPL"))

;;;###autoload
(defun steel-clear-repl ()
  "Clear the Steel REPL buffer (C-c C-l)."
  (interactive)
  (let ((buf (get-buffer steel-repl-buffer-name)))
    (when buf
      (with-current-buffer buf
        (let ((comint-buffer-maximum-size 0))
          (comint-truncate-buffer)))
      (message "Steel REPL cleared"))))

;;;###autoload
(defun steel-restart-repl ()
  "Restart the Steel REPL process (C-c C-k)."
  (interactive)
  (let ((proc (steel-proc)))
    (when proc
      (delete-process proc))
    (run-steel t)
    (message "Steel REPL restarted!")))

;;; ============================================================================
;;; Steel Scheme Syntax, Indentation & Keywords
;;; ============================================================================

(defconst steel-font-lock-keywords
  (eval-when-compile
    `((,(concat "(" (regexp-opt
                     '("define" "define-syntax" "syntax-rules" "syntax-case"
                       "struct" "lambda" "λ" "fn" "let" "let*" "letrec" "let%"
                       "if" "cond" "case" "when" "unless" "begin" "do"
                       "require" "provide" "transduce" "into-list" "into-vector"
                       "into-hash" "push!" "pop!" "clear!" "set!" "set-car!"
                       "set-cdr!" "test-module" "assert!" "assert-equal!"
                       "match" "match!" "quasiquote" "unquote" "unquote-splicing")
                     t)
                "\\>")
       1 font-lock-keyword-face)))
  "Additional syntax highlighting keywords for Steel Scheme.")

(defun steel-setup-indentation ()
  "Configure indentation rules for Steel Scheme forms."
  (put 'when 'scheme-indent-function 1)
  (put 'unless 'scheme-indent-function 1)
  (put 'struct 'scheme-indent-function 1)
  (put 'fn 'scheme-indent-function 1)
  (put 'λ 'scheme-indent-function 1)
  (put 'define-syntax 'scheme-indent-function 1)
  (put 'syntax-rules 'scheme-indent-function 1)
  (put 'syntax-case 'scheme-indent-function 2)
  (put 'match 'scheme-indent-function 1)
  (put 'transduce 'scheme-indent-function 1)
  (put 'test-module 'scheme-indent-function 1))

;; Prettify lambda / fn as λ
(defvar steel-prettify-symbols-alist
  '(("lambda" . ?λ)
    ("fn"     . ?λ)))

;;; ============================================================================
;;; Scheme Mode Hook & Keymap
;;; ============================================================================

(defvar steel-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Eval REPL shortcuts
    (define-key map (kbd "M-RET")        #'steel-eval-dwim)
    (define-key map (kbd "<M-return>")   #'steel-eval-dwim)
    (define-key map (kbd "C-RET")        #'steel-eval-dwim)
    (define-key map (kbd "<C-return>")   #'steel-eval-dwim)
    (define-key map (kbd "<s-return>")   #'steel-eval-dwim) ; macOS Cmd+Enter

    ;; Standard Scheme interaction bindings
    (define-key map (kbd "C-c C-c")      #'steel-send-definition)
    (define-key map (kbd "C-M-x")        #'steel-send-definition)
    (define-key map (kbd "C-c C-b")      #'steel-send-buffer)
    (define-key map (kbd "C-c C-r")      #'steel-send-region)
    (define-key map (kbd "C-c C-z")      #'steel-toggle-repl)
    (define-key map (kbd "C-c C-q")      #'steel-hide-repl)    ; Close REPL window
    (define-key map (kbd "C-c C-d")      #'steel-kill-repl)    ; Kill REPL process
    (define-key map (kbd "C-c C-l")      #'steel-clear-repl)
    (define-key map (kbd "C-c C-k")      #'steel-restart-repl)
    (define-key map (kbd "C-c C-s")      #'run-steel)

    ;; Apply the 17 Strict Paredit shortcuts directly into scheme keymap too
    (strict-paredit-apply-keys map)
    map)
  "Keymap for Steel Scheme mode.")

(define-minor-mode steel-mode
  "Minor mode for Steel Scheme development."
  :lighter " λ-Steel"
  :keymap steel-mode-map
  (if steel-mode
      (progn
        (font-lock-add-keywords nil steel-font-lock-keywords)
        (steel-setup-indentation)
        (setq-local prettify-symbols-alist steel-prettify-symbols-alist)
        (prettify-symbols-mode 1)
        (strict-paredit-enable))
    (font-lock-remove-keywords nil steel-font-lock-keywords)))

(defun steel-scheme-setup ()
  "Setup hook for Scheme buffers."
  (steel-setup-indentation)
  (steel-mode 1))

(add-hook 'scheme-mode-hook #'steel-scheme-setup)

;; Associate common Scheme / Steel file extensions
(add-to-list 'auto-mode-alist '("\\.scm\\'"   . scheme-mode))
(add-to-list 'auto-mode-alist '("\\.ss\\'"    . scheme-mode))
(add-to-list 'auto-mode-alist '("\\.steel\\'" . scheme-mode))
(add-to-list 'auto-mode-alist '("\\.rkt\\'"   . scheme-mode))

(provide 'steel-scheme)
;;; steel-scheme.el ends here
