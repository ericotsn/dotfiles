;;; init.el -*- lexical-binding: t; -*-

(eval-when-compile (require 'cl-lib))
(let ((emacs-start-time (current-time)))
  (add-hook 'emacs-startup-hook
            (lambda ()
              (let ((elapsed (float-time (time-subtract (current-time) emacs-start-time))))
                (message "[Emacs initialized in %.3fs]" elapsed)))))

;;; Built-in packages

;;;; Dired

(use-package dired
  :bind (:map dired-mode-map
         ("," . dired-up-directory))
  :config
  (setopt dired-dwim-target t)
  (setopt dired-kill-when-opening-new-dired-buffer t)
  (setopt dired-listing-switches "-AGFhlv --group-directories-first")
  (setopt dired-vc-rename-file t))

;;;; Ediff

(use-package ediff
  :config
  (setopt ediff-diff-options "-w")
  (setopt ediff-window-setup-function #'ediff-setup-windows-plain))

;;;; Eglot

(use-package eglot
  :bind (("C-c C-l" . eglot)
         :map eglot-mode-map
         ("C-c C-." . eglot-code-actions)
         ("C-c C-," . eglot-rename))
  :config
  (setopt eglot-autoshutdown t)
  (setopt eglot-extend-to-xref t)
  (setopt eldoc-echo-area-use-multiline-p nil))

;; When an LSP server responds to a codeAction request, it can omit
;; the edit property in the response.  Clients can then resolve
;; specific code actions lazily using a codeAction/resolve request.
;;
;; Eglot only sends this request if the command property is also
;; missing (Emacs 31.1), which can cause issues with some servers.
;;
;; This custom version of `eglot-execute' removes that check.
(cl-defgeneric my/eglot-execute (server action)
  "Ask SERVER to execute ACTION.
ACTION is an LSP `CodeAction', `Command' or `ExecuteCommandParams'
object."
  (:method
   (server action) "Default implementation."
   (eglot--dcase action
     (((Command))
      ;; Convert to ExecuteCommandParams and recurse (bug#71642)
      (cl-remf action :title)
      (eglot-execute server action))
     (((ExecuteCommandParams))
      (eglot--request server :workspace/executeCommand action))
     (((CodeAction) edit command data)
      (if (and (null edit) data
               (eglot-server-capable :codeActionProvider :resolveProvider))
          (eglot-execute server (eglot--request server :codeAction/resolve action))
        (when edit (eglot--apply-workspace-edit edit this-command))
        (when command
          ;; Recursive call with what must be a Command object (bug#71642)
          (eglot-execute server command)))))))

(advice-add 'eglot-execute :override #'my/eglot-execute)

;; A workspace edit can omit the documentChanges property, as it's
;; optional.  However, some servers still include it in the response
;; as an empty array.
;;
;; Eglot doesn't support this (Emacs 31.1), and an empty array in the
;; response causes an error.
;;
;; This custom version of `eglot--apply-workspace-edit' adds a check
;; for empty arrays to avoid that.
(defun my/eglot--apply-workspace-edit (wedit origin)
  "Apply (or offer to apply) the workspace edit WEDIT.
ORIGIN is a symbol designating the command that originated this
edit proposed by the server."
  (eglot--dbind ((WorkspaceEdit) changes documentChanges) wedit
    (let ((prepared
           (cl-remove-if
            (lambda (x) (cl-every #'null x))
            (mapcar (eglot--lambda ((TextDocumentEdit) textDocument edits)
                      (eglot--dbind ((VersionedTextDocumentIdentifier) uri version)
                          textDocument
                        (list (eglot-uri-to-path uri) edits version)))
                    documentChanges))))
      (unless (and changes documentChanges)
        ;; We don't want double edits, and some servers send both
        ;; changes and documentChanges.  This unless ensures that we
        ;; prefer documentChanges over changes.
        (cl-loop for (uri edits) on changes by #'cddr
                 do (push (list (eglot-uri-to-path uri) edits) prepared)))
      (cl-flet ((notevery-visited-p ()
                  (cl-notevery #'find-buffer-visiting
                               (mapcar #'car prepared)))
                (accept-p ()
                  (y-or-n-p
                   (format "[eglot] Server wants to edit:\n%sProceed? "
                           (cl-loop
                            for (f eds _) in prepared
                            concat (format
                                    "  %s (%d change%s)\n"
                                    f (length eds)
                                    (if (> (length eds) 1) "s" ""))))))
                (apply ()
                  (cl-loop for edit in prepared
                   for (path edits version) = edit
                   do (with-current-buffer (find-file-noselect path)
                        (eglot--apply-text-edits edits version))
                   finally (eldoc) (eglot--message "Edit successful!"))))
        (let ((decision (eglot--confirm-server-edits origin prepared)))
          (cond
           ((or (eq decision 'diff)
                (and (eq decision 'maybe-diff) (notevery-visited-p)))
            (eglot--propose-changes-as-diff prepared))
           ((or (memq decision '(t summary))
                (and (eq decision 'maybe-summary) (notevery-visited-p)))
            (when (accept-p) (apply)))
           (t
            (apply))))))))

(advice-add 'eglot--apply-workspace-edit :override #'my/eglot--apply-workspace-edit)

;;;; Emacs

(use-package emacs
  :bind (("C-<" . hs-hide-block)
         ("C->" . hs-show-block)
         ("C-x C-d" . duplicate-line)
         ("C-c z" . delete-trailing-whitespace))
  :config
  (setopt tab-width 4)
  (setopt fill-column 80)

  ;; Highlight trailing whitespace for programming modes
  (add-hook 'prog-mode-hook
            (lambda ()
              (setq show-trailing-whitespace t)))

  ;; Don't wrap lines while programming (toggle with C-x x t)
  (add-hook 'prog-mode-hook
            (lambda ()
              (setq truncate-lines t)))

  ;;; autorevert.el
  (global-auto-revert-mode 1)
  (setopt auto-revert-interval 0.1)

  ;;; bindings.el
  (when (version<= "31" emacs-version)
    (setopt mode-line-collapse-minor-modes t))

  ;;; cus-edit.el
  (setopt custom-file (make-temp-file "emacs-custom-"))

  ;;; delsel.el
  (delete-selection-mode 1)

  ;;; display-fill-column-indicator.el
  (add-hook 'prog-mode-hook
            (lambda ()
              (display-fill-column-indicator-mode 1)))

  ;;; files.el
  (setopt backup-directory-alist
          `((".*" . ,(expand-file-name
                      (concat user-emacs-directory "backups")))))
  (setopt delete-old-versions t)
  (setopt require-final-newline t)
  (setopt version-control t)

  ;;; novice.el
  (setq disabled-command-function nil)

  ;;; recentf.el
  (recentf-mode 1)

  ;;; savehist.el
  (savehist-mode 1)

  ;;; simple.el
  (column-number-mode 1)
  (setopt indent-tabs-mode nil)

  ;; Hide commands in M-x which do not work in the current mode
  (setopt read-extended-command-predicate #'command-completion-default-include-p))

;;;; Flymake

(use-package flymake
  :bind (:map flymake-mode-map
         ("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error))
  :config
  (setopt flymake-show-diagnostics-at-end-of-line t)

  ;; The default bitmaps used by Flymake don't scale appropriately on
  ;; high-resolution displays.  We address this by increasing the
  ;; fringe size and overriding the default bitmap symbols.
  (set-fringe-mode '(16 . 16))

  (defvar fringe-bitmap-double-arrow-hi-res
    [#b0000000000000000
     #b0000000000000000
     #b1111001111000000
     #b0111100111100000
     #b0011110011110000
     #b0001111001111000
     #b0000111100111100
     #b0000011110011110
     #b0000011110011110
     #b0000111100111100
     #b0001111001111000
     #b0011110011110000
     #b0111100111100000
     #b1111001111000000
     #b0000000000000000
     #b0000000000000000])

  (define-fringe-bitmap 'exclamation-mark
    fringe-bitmap-double-arrow-hi-res nil 16)

  (define-fringe-bitmap 'flymake-double-exclamation-mark
    fringe-bitmap-double-arrow-hi-res nil 16))

;;;; Tree-sitter

(use-package dockerfile-ts-mode
  :mode ("\\Dockerfile\\'" "\\.dockerignore\\'"))

(use-package elixir-ts-mode
  :mode ("\\.ex[s]?\\'" "\\mix.lock\\'"))

(use-package json-ts-mode
  :mode ("\\.json\\'"))

(use-package toml-ts-mode
  :mode ("\\.toml\\'"))

(use-package tsx-ts-mode
  :mode ("\\.[jt]sx\\'"))

(use-package js-ts-mode
  :mode ("\\.[cm]?js\\'"))

(use-package typescript-ts-mode
  :mode ("\\.[cm]?ts\\'"))

(use-package yaml-ts-mode
  :mode ("\\.ya?ml\\'"))

;;; Third-party packages

;;;; Avy

(use-package avy
  :bind (("C-'" . avy-goto-word-1)
         :map isearch-mode-map
         ("C-'" . avy-isearch))
  :config
  (setopt avy-single-candidate-jump nil)

  (defun avy-action-embark (pt)
    (unwind-protect
        (save-excursion
          (goto-char pt)
          (embark-act))
      (select-window
       (cdr (ring-ref avy-ring 0))))
    t)

  (setf (alist-get ?. avy-dispatch-alist) #'avy-action-embark))

;;;; Cape

(use-package cape
  :bind ("C-c p" . cape-prefix-map)
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;;;; Consult

(use-package consult
  :bind (;; C-x bindings in `ctl-x-map'
         ("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x p b" . consult-project-buffer)
         ("C-x C-r" . consult-recent-file)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)
         ;; M-g bindings in `goto-map'
         ("M-g o" . consult-outline)
         ;; M-s bindings in `search-map'
         ("M-s g" . consult-ripgrep)
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)
         ("M-r" . consult-history))
  :init
  (with-eval-after-load 'em-hist
    (keymap-set eshell-hist-mode-map "M-r" #'consult-history))

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref)
  (setq xref-show-definitions-function #'consult-xref))

;;;; Corfu

(use-package corfu
  :config
  ;; Enable indentation+completion using the TAB key
  (setopt tab-always-indent 'complete)

  ;; Disable Ispell completion function
  (setopt text-mode-ispell-word-completion nil)

  (setopt corfu-cycle t)
  (setopt corfu-preselect 'prompt)
  (setopt corfu-quit-no-match 'separator)

  ;; Free the RET key for less intrusive behavior
  (keymap-unset corfu-map "RET")

  (global-corfu-mode 1))

(use-package corfu-popupinfo
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode)
  :config
  (setopt corfu-popupinfo-delay '(nil . 0.2))
  (setopt corfu-popupinfo-max-height 20))

(use-package corfu-quick
  :after corfu
  :bind (:map corfu-map
         ("'" . corfu-quick-complete))
  :config
  (setopt corfu-quick1 "arstgmneio"))

;;;; Eat

(use-package eat
  :hook (eshell-mode . eat-eshell-mode))

;;;; Eglot booster

(use-package eglot-booster
  :after eglot
  :config
  (setopt eglot-booster-io-only t)
  (eglot-booster-mode 1))

;;;; Embark

(use-package embark
  :demand t
  :bind (("C-." . embark-act)
         ("M-." . embark-dwim)
         ("C-h b" . embark-bindings)
         :map minibuffer-local-map
         ("C-c C-c" . embark-collect)
         ("C-c C-e" . embark-export))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)

  :config
  ;; Embark actions for this buffer/file
  (defun embark-target-this-buffer-file ()
    (cons 'this-buffer-file (buffer-name)))

  (add-to-list 'embark-target-finders #'embark-target-this-buffer-file 'append)

  (defvar-keymap embark-this-buffer-file-map
    :doc "Commands to act on the current file or buffer."
    :parent embark-general-map)

  (add-to-list 'embark-keymap-alist
               '(this-buffer-file . embark-this-buffer-file-map)))

(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;;; Envrc

(use-package envrc
  :init
  (envrc-global-mode 1))

;;;; Expand region

(use-package expand-region
  :bind ("C-," . er/expand-region))

;;;; Forge

(use-package forge
  :after magit
  :config
  ;; Hide issues from the `magit' status buffer
  (remove-hook 'magit-status-sections-hook 'forge-insert-issues))

;;;; Gptel

(use-package gptel
  :bind (("C-c <return>" . gptel-send)
         ("C-c j" . gptel-menu)
         ("C-c C-j" . gptel)
         ("C-c r" . gptel-rewrite)
         ("C-c C-g" . gptel-abort)
         :map embark-region-map
         ("+" . gptel-add)
         :map embark-this-buffer-file-map
         ("+" . gptel-add))
  :hook (gptel-mode . visual-line-mode)
  :config
  (setopt gptel-default-mode 'org-mode)

  (setf (alist-get 'org-mode gptel-prompt-prefix-alist) "*Prompt*: ")
  (setf (alist-get 'org-mode gptel-response-prefix-alist) "*Response*:\n")

  (require 'gptel-gh)

  (defvar gptel--copilot
    (gptel-make-gh-copilot "Copilot"))

  (setopt gptel-model 'claude-sonnet-4)
  (setopt gptel-backend gptel--copilot))

;;;; Helpful

(use-package helpful
  :bind (("C-c C-d" . helpful-at-point)
         ([remap describe-command] . helpful-command)
         ([remap describe-function] . helpful-callable)
         ([remap describe-key] . helpful-key)
         ([remap describe-variable] . helpful-variable)
         ([remap describe-symbol] . helpful-symbol)))

;;;; Jinx

(use-package jinx
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages))
  :hook ((text-mode org-mode markdown-mode) . jinx-mode))

;;;; Magit

(use-package magit
  :config
  (setopt magit-define-global-key-bindings 'recommended)
  (setopt magit-diff-refine-hunk 'all)

  (transient-bind-q-to-quit)

  (defun my/magit-disable-whitespace-mode ()
    "Disable `whitespace-mode' in Magit buffers."
    (whitespace-mode -1))

  (add-hook 'magit-section-mode-hook #'my/magit-disable-whitespace-mode))

;;;; Marginalia

(use-package marginalia
  :init
  (marginalia-mode 1))

;;;; Markdown mode

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)))

;;;; Modus themes

(use-package modus-themes
  :demand t
  :bind ("C-c t t" . modus-themes-toggle)
  :config
  (setopt modus-themes-italic-constructs t)
  (setopt modus-themes-prompts '(bold))
  (setopt modus-themes-to-toggle '(modus-operandi modus-vivendi))

  (setopt modus-themes-common-palette-overrides
          `((fg-region unspecified)))

  (defun my/modus-themes-flymake-faces (&rest _)
    (modus-themes-with-colors
      (custom-set-faces
       `(flymake-error-echo-at-eol ((,c :foreground ,red-cooler :background ,bg-red-nuanced)))
       `(flymake-note-echo-at-eol ((,c :foreground ,cyan-cooler :background ,bg-cyan-nuanced )))
       `(flymake-warning-echo-at-eol ((,c :foreground ,yellow-cooler :background ,bg-yellow-nuanced))))))

  (add-hook 'modus-themes-post-load-hook #'my/modus-themes-flymake-faces)

  (modus-themes-load-theme (cadr modus-themes-to-toggle)))

;;;; Move text

(use-package move-text
  :bind (("C-M-n" . move-text-down)
         ("C-M-p" . move-text-up))
  :config
  (move-text-default-bindings)

  (defun indent-region-advice (&rest ignored)
    (let ((deactivate deactivate-mark))
      (if (region-active-p)
          (indent-region (region-beginning) (region-end))
        (indent-region (line-beginning-position) (line-end-position)))
      (setq deactivate-mark deactivate)))

  (advice-add 'move-text-up :after #'indent-region-advice)
  (advice-add 'move-text-down :after #'indent-region-advice))

;;;; Nix mode

(use-package nix-mode
  :mode "\\.nix\\'"
  :config
  (setopt nix-indent-function 'nix-indent-line))

;;;; Orderless

(use-package orderless
  :config
  (setopt completion-styles '(orderless flex))
  (setopt completion-category-overrides '((eglot (styles . (orderless flex)))
                                          (file (styles . (partial-completion)))))
  (setopt completion-category-defaults nil)
  (setopt completion-pcm-leading-wildcard t))

;;;; Org mode

(use-package org
  :config
  (setopt org-M-RET-may-split-line '((default . nil)))
  (setopt org-insert-heading-respect-content t)

  (keymap-unset org-mode-map "C-'")
  (keymap-unset org-mode-map "C-,")
  (keymap-unset org-mode-map "C-c C-j"))

;;;; PragmataPro mode

(use-package pragmatapro-mode
  :hook (prog-mode . pragmatapro-mode)
  :config
  (setopt pragmatapro-enable-ligatures-in-comments t))

;;;; Vertico

(use-package vertico
  :config
  (setopt vertico-cycle t)

  (vertico-mode 1))

(use-package vertico-multiform
  :after vertico
  :config
  (setopt vertico-multiform-commands
          '((consult-ripgrep buffer)
            (consult-xref buffer)
            (embark-bindings buffer)))

  (vertico-multiform-mode 1))

;;;; Wgrep

(use-package wgrep
  :config
  (setopt wgrep-auto-save-buffer t))

;;;; Yasnippet

(use-package yasnippet
  :config
  (setopt yas-triggers-in-field t)
  (setopt yas-wrap-around-region t)

  (yas-global-mode 1))

;; Local Variables:
;; outline-minor-mode-cycle: t
;; outline-regexp: ";;;;* [^ 	\n]"
;; eval: (outline-minor-mode)
;; End:
