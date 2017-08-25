;;----------------------------------------------------------------------------
;; copy file name function
;;----------------------------------------------------------------------------
(defun copy-file-name-to-clipboard ()
  "Copy the current buffer file name to the clipboard."
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode)
                      default-directory
                    (buffer-file-name))))
    (when filename
      (kill-new filename)
      (message "Copied buffer file name '%s' to the clipboard." filename))))

;;----------------------------------------------------------------------------
;; move line
;;----------------------------------------------------------------------------
(defun move-line (n)
  "Move the current line up or down by N lines."
  (interactive "p")
  (setq col (current-column))
  (beginning-of-line) (setq start (point))
  (end-of-line) (forward-char) (setq end (point))
  (let ((line-text (delete-and-extract-region start end)))
    (forward-line n)
    (insert line-text)
    ;; restore point to original column in moved line
    (forward-line -1)
    (forward-char col)))

(defun move-line-up (n)
  "Move the current line up by N lines."
  (interactive "p")
  (move-line (if (null n) -1 (- n))))

(defun move-line-down (n)
  "Move the current line down by N lines."
  (interactive "p")
  (move-line (if (null n) 1 n)))

(bind-key* "M-S-<up>" 'move-line-up)
(bind-key* "M-S-<down>" 'move-line-down)
;;----------------------------------------------------------------------------
;;avy 随意跳
;;----------------------------------------------------------------------------
(global-set-key (kbd "C-:") 'avy-goto-char)
;;----------------------------------------------------------------------------
;;光标
;;----------------------------------------------------------------------------
(blink-cursor-mode 1)
(setq cursor-in-non-selected-windows nil)
(global-hl-line-mode 1)
;;----------------------------------------------------------------------------
;;优化注释 emacs 25.1 注释掉的暂时不能用了，使用新增的 comment-line;
;;----------------------------------------------------------------------------
;; (defun qiang-comment-dwim-line (&optional arg)
;;   (interactive "*P")
;;   (comment-normalize-vars)
;;   (if (and (not (region-active-p)) (not (looking-at "[ \t]*$")))
;;       (comment-or-uncomment-region (line-beginning-position) (line-end-position))
;;     (comment-dwim arg)))
;; (global-set-key "\M-;" 'qiang-comment-dwim-line)

;; comment/uncomment code
;;(require 'bind-key)
(bind-key* "M-;" 'comment-line)
;;(global-set-key (kbd "C-c C-c") 'comment-line)
;;----------------------------------------------------------------------------
;; 跳转成对的括号
;;----------------------------------------------------------------------------
(global-set-key "%" 'match-paren)
(defun match-paren (arg)
  "Go to the matching paren if on a paren; otherwise insert %."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
        (t (self-insert-command (or arg 1)))))

;;----------------------------------------------------------------------------
;;多窗口管理M-1 暂时不需要，用 c-x o 更酷炫
;;----------------------------------------------------------------------------
;;(require 'window-numbering)
;;(window-numbering-mode 1)

;;----------------------------------------------------------------------------
;; 在标题栏显示一些
;;----------------------------------------------------------------------------
(setq frame-title-format '("" "%b @ %f     Emacs " emacs-version))


;;----------------------------------------------------------------------------
;;evil-mode
;;----------------------------------------------------------------------------
(require 'evil)
(evil-mode 1)


;;----------------------------------------------------------------------------
;;未选中复制或者剪切当前行
;;----------------------------------------------------------------------------
(global-set-key "\M-w"
                (lambda ()
                  (interactive)
                  (if mark-active
                      (kill-ring-save (region-beginning)
                                      (region-end))
                    (progn
                      (kill-ring-save (line-beginning-position)
                                      (line-end-position))
                      (message "复制了一整行!")))))
(global-set-key "\C-w"
                (lambda ()
                  (interactive)
                  (if mark-active
                      (kill-region (region-beginning)
                                   (region-end))
                    (progn
                      (kill-region (line-beginning-position)
                                   (line-end-position))
                      (message "剪切了一整行!")))))


;;----------------------------------------------------------------------------
;; c++
;;----------------------------------------------------------------------------
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(add-to-list 'load-path "~/.emacs.d/custom")

(require 'setup-general)
(if (version< emacs-version "24.4")
    (require 'setup-ivy-counsel)
  (require 'setup-helm)
  (require 'setup-helm-gtags))
;; (require 'setup-ggtags)
(require 'setup-cedet)
(require 'setup-editing)


;;----------------------------------------------------------------------------
;; 字体
;;----------------------------------------------------------------------------
(defun qiang-font-existsp (font)
  (if (null (x-list-fonts font))
      nil t))

(defun qiang-make-font-string (font-name font-size)
  (if (and (stringp font-size)
           (equal ":" (string (elt font-size 0))))
      (format "%s%s" font-name font-size)
    (format "%s-%s" font-name font-size)))

(defvar bhj-english-font-size nil)
(defun qiang-set-font (english-fonts
                       english-font-size
                       chinese-fonts
                       &optional chinese-fonts-scale
                       )
  (setq chinese-fonts-scale (or chinese-fonts-scale 1.2))
  (save-excursion
    (with-current-buffer (find-file-noselect "~/.config/system-config/emacs-font-size")
      (delete-region (point-min) (point-max))
      (insert (format "%s" english-font-size))
      (save-buffer)
      (kill-buffer)))
  (setq face-font-rescale-alist `(("Microsoft Yahei" . ,chinese-fonts-scale)
                                  ("Microsoft_Yahei" . ,chinese-fonts-scale)
                                  ("微软雅黑" . ,chinese-fonts-scale)
                                  ("WenQuanYi Zen Hei" . ,chinese-fonts-scale)))
  "english-font-size could be set to \":pixelsize=18\" or a integer.
If set/leave chinese-font-size to nil, it will follow english-font-size"
  (require 'cl)                         ; for find if
  (setq bhj-english-font-size english-font-size)
  (let ((en-font (qiang-make-font-string
                  (find-if #'qiang-font-existsp english-fonts)
                  english-font-size))
        (zh-font (font-spec :family (find-if #'qiang-font-existsp chinese-fonts))))

    ;; Set the default English font
    ;;
    ;; The following 2 method cannot make the font settig work in new frames.
    ;; (set-default-font "Consolas:pixelsize=18")
    ;; (add-to-list 'default-frame-alist '(font . "Consolas:pixelsize=18"))
    ;; We have to use set-face-attribute
    (set-face-attribute
     'default nil :font en-font)
    (condition-case font-error
        (progn
          (set-face-font 'italic (font-spec :family "Courier New" :slant 'italic :weight 'normal :size (+ 0.0 english-font-size)))
          (set-face-font 'bold-italic (font-spec :family "Courier New" :slant 'italic :weight 'bold :size (+ 0.0 english-font-size)))

          (set-fontset-font t 'symbol (font-spec :family "Courier New")))
      (error nil))
    (set-fontset-font t 'symbol (font-spec :family "Unifont") nil 'append)
    (set-fontset-font t nil (font-spec :family "DejaVu Sans"))

    ;; Set Chinese font
    ;; Do not use 'unicode charset, it will cause the english font setting invalid
    (dolist (charset '(kana han cjk-misc bopomofo))
      (set-fontset-font t charset zh-font)))
  (when (and (boundp 'global-emojify-mode)
             global-emojify-mode)
    (global-emojify-mode 1))
  (shell-command-to-string "sawfish-client -e '(maximize-window (input-focus))'&"))


(defvar bhj-english-fonts '("Source Code Pro" "Consolas" "DejaVu Sans Mono" "Monospace" "Courier New"))
(defvar bhj-chinese-fonts '("Microsoft Yahei" "Microsoft_Yahei" "微软雅黑" "文泉驿等宽微米黑" "黑体" "新宋体" "宋体"))

(qiang-set-font
 bhj-english-fonts
 (if (file-exists-p "~/.config/system-config/emacs-font-size")
     (save-excursion
       (find-file "~/.config/system-config/emacs-font-size")
       (goto-char (point-min))
       (let ((monaco-font-size (read (current-buffer))))
         (kill-buffer (current-buffer))
         monaco-font-size))
   12.5)
 bhj-chinese-fonts)

(defvar chinese-font-size-scale-alist nil)

;; On different platforms, I need to set different scaling rate for
;; differnt font size.
(cond
 ((and (boundp '*is-a-mac*) *is-a-mac*)
  (setq chinese-font-size-scale-alist '((10.5 . 1.3) (11.5 . 1.3) (16 . 1.3) (18 . 1.25))))
 ((and (boundp '*is-a-win*) *is-a-win*)
  (setq chinese-font-size-scale-alist '((11.5 . 1.25) (16 . 1.25))))
 (t ;; is a linux:-)
  (setq chinese-font-size-scale-alist '((16 . 1.25)))))

(defvar bhj-english-font-size-steps '(9 10.5 11.5 12.5 14 16 18 20 22))
(defun bhj-step-frame-font-size (step)
  (let ((steps bhj-english-font-size-steps)
        next-size)
    (when (< step 0)
      (setq steps (reverse bhj-english-font-size-steps)))
    (setq next-size
          (cadr (member bhj-english-font-size steps)))
    (when next-size
      (qiang-set-font bhj-english-fonts next-size bhj-chinese-fonts (cdr (assoc next-size chinese-font-size-scale-alist)))
      (message "Your font size is set to %.1f" next-size))))

(global-set-key [(control x) (meta -)] (lambda () (interactive) (bhj-step-frame-font-size -1)))
(global-set-key [(control x) (meta =)] (lambda () (interactive) (bhj-step-frame-font-size 1)))

(set-face-attribute 'default nil :font (font-spec))


;;----------------------------------------------------------------------------
;; elpa mirror 
;;----------------------------------------------------------------------------
;;(setq package-archives '(("myelpa" . "~/myelpa")))
;;(setq elpamr-default-output-directory "~/myelpa")

;;----------------------------------------------------------------------------
;; org-mode
;;----------------------------------------------------------------------------
(setq org-todo-keywords
      '((type "工作(w!)" "个人(m!)" "|")
        (sequence "PENDING(p!)" "TODO(t!)" "NEXT(n!)" "|" "DONE(d!)" "ABORT(a@/!)")
        ))

(setq org-todo-keyword-faces
  '(("工作" .      (:background "red" :foreground "white" :weight bold))
    ("个人" .      (:background "white" :foreground "red" :weight bold))
    ("PENDING" .   (:background "LightGreen" :foreground "gray" :weight bold))
    ("TODO" .      (:background "DarkOrange" :foreground "black" :weight bold))
    ("NEXT" .      (:background "DarkOrange" :foreground "black" :weight bold))
    ("DONE" .      (:background "azure" :foreground "Darkgreen" :weight bold)) 
    ("ABORT" .     (:background "gray" :foreground "black"))
))


(provide 'init-local)

