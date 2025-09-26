;;; early-init.el -*- lexical-binding: t; -*-

;; Temporarily increase the garbage collection threshold to improve
;; startup time.  This optimization saves me about 0.3s.  It's VERY
;; IMPORTANT to reset `gc-cons-threshold' after Emacs has loaded to
;; ensure normal operation.
(setq gc-cons-threshold most-positive-fixnum)
(setq gc-cons-percentage 0.5)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 128 1024 1024)) ; 128 MB
            (setq gc-cons-percentage 0.1)))

;; Emacs uses a conservative default chunk size of 0.625 MB when
;; reading data from subprocesses.  Increasing it can help improve
;; performance for tools like LSP servers, which require processing
;; large amounts of data.
(setq read-process-output-max (* 4 1024 1024)) ; 4 MB
(setq process-adaptive-read-buffering nil)

;; The early-init.el file is loaded before the GUI is initialized,
;; which makes it possible to disable UI elements, change settings,
;; and configure fonts before the initial frame is rendered.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)
(push '(background-color . "#000000") default-frame-alist)

(setq inhibit-startup-screen t)
(setq initial-buffer-choice t)

;; Show the current file's full path in the title
(setq frame-title-format
      '(:eval (if buffer-file-name default-directory "%b")))

(set-face-attribute 'default nil :family "PragmataPro Liga" :height 150)
