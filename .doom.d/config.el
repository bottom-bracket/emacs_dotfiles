;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Philip Heringlake"
      user-mail-address "p.heringlake@mailbox.com")
;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font (font-spec :family "monospace" :size 14))
(setq doom-big-font (font-spec :family "monospace" :size 20))
;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-acario-light)
;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/org/")
;; This determines the style of line numbers in effect. If set to `nil', line
 ;; numbers are disabled. For relative line numbers, set this to `relative'.
 ;;(setq display-line-numbers-type relative)
(setq display-line-number-width 4)
(setq show-trailing-whitespace t
      delete-by-moving-to-trash t
      trash-directory "~/.local/share/Trash/files"
)
(use-package! popup-kill-ring)
(use-package! evil-collection
;    :after
;    (setq evil-want-keybinding nil)
    :config
    (evil-collection-init)
  )

(use-package! evil-surround
  :ensure t
  :config
  (global-evil-surround-mode 1))
(load! "bindings/spacemacs.el")
(map! :map org-mode-map
     :localleader
     :desc "Reference" "l r" #'org-ref-helm-insert-ref-link
     :desc "Toggle Link display" "L" #'org-toggle-link-display
     :desc "Toggle LaTeX fragment" "X" #'org-latex-preview
     :desc "Copy Email html to clipboard" "M" #'export-org-email
     :desc "Screenshot" "S" #'org-screenshot-take
;     (:prefix "o"
;       :desc "Tags" "t" 'org-set-tags
;       (:prefix ("p" . "Properties")
;         :desc "Set" "s" 'org-set-property
;         :desc "Delete" "d" 'org-delete-property
;         :desc "Actions" "a" 'org-property-action
;         )
;       )
     (:prefix ("H" . "Headings")
         :desc "Normal Heading" "h" #'org-insert-heading
         :desc "Todo Heading" "H" #'org-insert-todo-heading
         :desc "Normal Subheading" "s" #'org-insert-subheading
         :desc "Todo Subheading" "S" #'org-insert-todo-subheading)
     )
(use-package! helm-files
  :bind
  (:map helm-find-files-map
   ("C-h" . helm-find-files-up-one-level)
   ("C-l" . helm-execute-persistent-action))
)
(map! :leader
      (:prefix ("y" . "Useful Hydra Menus")
        :desc "Spelling" "s" #'hydra-spelling/body))
;; (map!
;;  (:prefix "z"
;;    :desc "evil/vimish-fold-toggle" "g" #'vimish-fold-toggle))
(map! :leader
     (:prefix "o"
       :desc "Ipython REPL" "i" #'+python/open-ipython-repl))
;; in my setup it is prior and next that are define the Page Up/Down buttons
(map!
 "<prior>" nil
 "<next>" nil
 "<PageDown>" nil
 "<PageUp>" nil)
(defun org-get-target-headline (&optional targets prompt)
  "Prompt for a location in an org file and jump to it.

This is for promping for refile targets when doing captures.
Targets are selected from `org-refile-targets'. If TARGETS is
given it temporarily overrides `org-refile-targets'. PROMPT will
replace the default prompt message.

If CAPTURE-LOC is is given, capture to that location instead of
prompting."
  (let ((org-refile-targets (or targets org-refile-targets))
        (prompt (or prompt "Capture Location")))
    (if org-capture-overriding-marker
        (org-goto-marker-or-bmk org-capture-overriding-marker)
      (org-refile t nil nil prompt)))
  )

(defun org-ask-location ()
  (let* ((org-refile-targets '((nil :maxlevel . 9)))
         (hd (condition-case nil
                 (car (org-refile-get-location "Headline" nil t))
               (error (car org-refile-history)))))
    (goto-char (point-min))
    (outline-next-heading)
    (if (re-search-forward
         (format org-complex-heading-regexp-format (regexp-quote hd))
        nil t)
      (goto-char (point-at-bol))
      (goto-char (point-max))
      (or (bolp) (insert "\n"))
      (insert "* " hd "\n")))
    (end-of-line))
;; (setq org-outline-path-complete-in-steps nil)         ; Refile in a single go
(after! org
  (setq org-refile-use-outline-path nil))                  ; Show full paths for refiling
(defun insert-todays-date (arg)
  (interactive "P")
  (insert (if arg
              (format-time-string "%d-%m-%Y")
            (format-time-string "%Y-%m-%d"))))
(global-set-key (kbd "C-c d") 'insert-todays-date)
;; Show the current function name in the header line
(which-function-mode)
(setq-default header-line-format
              '((which-function-mode ("" which-func-format " "))))
(setq mode-line-misc-info
            ;; We remove Which Function Mode from the mode line, because it's mostly
            ;; invisible here anyway.
            (assq-delete-all 'which-function-mode mode-line-misc-info))
(defcustom org-html-image-base64-max-size #x40000
  "Export embedded base64 encoded images up to this size."
  :type 'number
  :group 'org-export-html)

(defun file-to-base64-string (file &optional image prefix postfix)
  "Transform binary file FILE into a base64-string prepending PREFIX and appending POSTFIX.
Puts \"data:image/%s;base64,\" with %s replaced by the image type before the actual image data if IMAGE is non-nil."
  (concat prefix
      (with-temp-buffer
        (set-buffer-multibyte nil)
        (insert-file-contents file nil nil nil t)
        (base64-encode-region (point-min) (point-max) 'no-line-break)
        (when image
          (goto-char (point-min))
          (insert (format "data:image/%s;base64," (image-type-from-file-name file))))
        (buffer-string))
      postfix))

(defun orgTZA-html-base64-encode-p (file)
  "Check whether FILE should be exported base64-encoded.
The return value is actually FILE with \"file://\" removed if it is a prefix of FILE."
  (when (and (stringp file)
             (string-match "\\`file://" file))
    (setq file (substring file (match-end 0))))
  (and
   (file-readable-p file)
   (let ((size (nth 7 (file-attributes file))))
     (<= size org-html-image-base64-max-size))
   file))

(defun orgTZA-html--format-image (source attributes info)
  "Return \"img\" tag with given SOURCE and ATTRIBUTES.
SOURCE is a string specifying the location of the image.
ATTRIBUTES is a plist, as returned by
`org-export-read-attribute'.  INFO is a plist used as
a communication channel."
  (if (string= "svg" (file-name-extension source))
      (org-html--svg-image source attributes info)
    (let* ((file (orgTZA-html-base64-encode-p source))
           (data (if file (file-to-base64-string file t)
                   source)))
      (org-html-close-tag
       "img"
       (org-html--make-attribute-string
        (org-combine-plists
         (list :src data
               :alt (if (string-match-p "^ltxpng/" source)
                        (org-html-encode-plain-text
                         (org-find-text-property-in-string 'org-latex-src source))
                      (file-name-nondirectory source)))
         attributes))
       info))))

(advice-add 'org-html--format-image :override #'orgTZA-html--format-image)

(defun export-org-email ()
  "Export the current org email and copy it to the clipboard"
  (interactive)
  (let ((org-export-show-temporary-export-buffer nil)
        (org-html-head (org-email-html-head)))
    (org-html-export-as-html)
    (with-current-buffer "*Org HTML Export*"
      (kill-new (buffer-string)))
    (message "HTML copied to clipboard")))

(defun org-email-html-head ()
  "Create the header with CSS for use with email"
  (concat
   "<style type=\"text/css\">\n"
   "<!--/*--><![CDATA[/*><!--*/\n"
   (with-temp-buffer
     (insert-file-contents
      "~/Documents/org/setupfiles/org-html-themes/styles/email/css/email.css")
     (buffer-string))
   "/*]]>*/-->\n"
   "</style>\n"))
(after! flyspell
  (setq flyspell-abbrev-p t))
(after! abbrev
  (setq abbrev-file-name "~/.dotfiles/abbrev_defs"))
(defhydra hydra-spelling (:color blue)
  "
  ^
  ^Spelling^          ^Errors^            ^Checker^
  ^────────^──────────^──────^────────────^───────^───────
  _q_ quit            _p_ previous        _c_ correction
  ^^                  _n_ next            _d_ dictionary
  ^^                  _f_ check           _m_ mode
  ^^                  ^^                  ^^
  "
  ("q" nil)
  ("p" flyspell-correct-previous :color pink)
  ("n" flyspell-correct-next :color pink)
  ("c" ispell)
  ("d" ispell-change-dictionary)
  ("f" flyspell-buffer)
  ("m" flyspell-mode))
;; (use-package! company-tabnine
;;   )

(after! (:any company)
(setq-default company-backends
                `((company-capf         ; `completion-at-point-functions'
                   ;; :separate company-tabnine
                   :separate company-yasnippet
                   :separate company-keywords
                   :separate company-abbrev
                   :separate company-files)
                  company-ispell
                  company-dabbrev-code
                  company-files))
  (use-package! company-math
    :after TeX-mode
    :config
    (set-company-backend! 'TeX-mode 'company-math-symbols-latex)
    (set-company-backend! 'TeX-mode 'company-latex-commands)
    (setq company-tooltip-align-annotations t)
    (setq company-math-allow-latex-symbols-in-faces t))

  ;; (add-to-list 'company-backends #'company-tabnine)
  (add-to-list 'company-backends #'company-files)
  (set-company-backend! 'org-mode
      '(:separate company-capf
        company-keywords       ; keywords
        :separate company-yasnippet
        :separate company-dabbrev
        ;; :separate company-tabnine
        :separate company-ispell
        :separate company-files
     ; company-math-symbols-latex ; may  not need those as there is cdlatex mode
     ; company-latex-commands
     ))
  (setq +lsp-company-backend '(company-capf))
  ;  :with company-files
  ;  company-tabnine
  ;  :separate
  ;; Trigger completion immediately.
  (setq company-idle-delay 0)
  ;; Number the candidates (use M-1, M-2 etc to select completions).
  (setq company-show-numbers t)
  (map! :map company-active-map
        "<tab>" nil
        "TAB" nil
        "C-SPC" 'company-complete-common-or-cycle))
(after! helm
(setq helm-ff-auto-update-initial-value 1)
(setq helm-mode-fuzzy-match t)
(setq helm-completion-in-region-fuzzy-match t)
)
(after! latex
(add-to-list
  'TeX-command-list
  '("latexmk_shellesc"
    "latexmk -shell-escape -bibtex -f -pdf %f"
    TeX-run-command
    nil                              ; ask for confirmation
    t                                ; active in all modes
    :help "Latexmk as for org"))

(setq LaTeX-command-style '(("" "%(PDF)%(latex) -shell-escape %S%(PDFout)")))
)
(after! latex
  (add-hook 'LaTex-mode-hook 'turn-on-cdlatex))
(after! cdlatex
 (setq cdlatex-command-alist '(("ang"         "Insert \\ang{}"
                               "\\ang{?}" cdlatex-position-cursor nil t t)
                              ("si"          "Insert \\SI{}{}"
                               "\\SI{?}{}" cdlatex-position-cursor nil t t)
                              ("sl"          "Insert \\SIlist{}{}"
                               "\\SIlist{?}{}" cdlatex-position-cursor nil t t)
                              ("sr"          "Insert \\SIrange{}{}{}"
                               "\\SIrange{?}{}{}" cdlatex-position-cursor nil t t)
                              ("num"         "Insert \\num{}"
                               "\\num{?}" cdlatex-position-cursor nil t t)
                              ("nl"          "Insert \\numlist{}"
                               "\\numlist{?}" cdlatex-position-cursor nil t t)
                              ("nr"          "Insert \\numrange{}{}"
                               "\\numrange{?}{}" cdlatex-position-cursor nil t t))) )
(add-hook 'eshell-mode-hook #'hide-mode-line-mode)
(add-hook 'term-mode-hook #'hide-mode-line-mode)
(add-hook 'org-capture-mode-hook 'evil-insert-state)
(use-package! helm-org-rifle)
(after! org
(setq org-directory "/home/philip/Documents/org/"
      org-archive-location (concat org-directory "archive/%s::")
      +org-capture-journal-file (concat org-directory "tagebuechlein.org.gpg")))
(after! org
  (setq org-log-done 'time))
(after! org
(add-hook 'org-mode-hook 'turn-on-org-cdlatex))
(after! evil-org
  (remove-hook 'org-tab-first-hook #'+org-cycle-only-current-subtree-h))
(setq org-goto-interface 'outline-path-completion
      org-goto-max-level 10)
(use-package! org-preview-html)
(after! org
  (setq org-export-with-toc nil))
(require 'ox-extra)
(ox-extras-activate '(latex-header-blocks ignore-headlines))
(setq org-reveal-root "https://cdn.jsdelivr.net/npm/reveal.js")
(setq org-confirm-babel-evaluate nil
      org-use-speed-commands t
      org-catch-invisible-edits 'show)
(after! org
(setq org-capture-templates
     '(("w" "PhD work templates")
       ("wa"               ; key
        "Article"         ; name
        entry             ; type
        (file+headline "PhD.org.gpg" "Article")  ; target
        "* %^{Title} %(org-set-tags)  :article: \n:PROPERTIES:\n:Created: %U\n:Linked: %a\n:END:\n%i\nBrief description:\n%?"  ; template
        :prepend t        ; properties
        :empty-lines 1    ; properties
        :created t        ; properties
        )
       ("wf" "Link file in index" entry
            (file+function "~/Documents/Research/index.org" org-ask-location)
           "** %A \n:PROPERTIES:\n:Created: %U \n:FromDate: %^u \n:Linked: %f\n:END: \n %^g %?"
           :empty-lines 1
           )
       ("wt" "TODO template" entry
        (file+headline "PhD.org.gpg" "Capture")
        ( file "tpl_todo.txt" ) :empty-lines-before 1)
       ("wl" "Logbook entry" entry (file+datetree "phd_journal.org.gpg") "** %U - %^{Activity}  :LOG:")
       ("ww" "Link" entry (file+headline "PhD.org.gpg" "Links") "* %? %^L %^g \n%T" :prepend t)
       ("wn" "Note" entry (file+headline "PhD.org.gpg" "Notes")
        "* NOTE %?\n%U" :empty-lines 1)
       ("wN" "Note with Clipboard" entry (file+headline "PhD.org.gpg" "Notes")
        "* NOTE %?\n%U\n   %c" :empty-lines 1)
       ;; MEETING  (m) Meeting template
       ("wm" "MEETING   (m) Meeting" entry (file+headline "PhD.org.gpg" "Unsorted Meetings")
        "* %^{Meeting Title}
SCHEDULED: %^T
:PROPERTIES:
:Attend:   Philip Heringlake,
:Location:
:Agenda:
:Note:
:END:
:LOGBOOK:
- State \"MEETING\"    from \"\"           %U
:END:
%?" :empty-lines 1)
       ("bd" "Note" entry (file+headline "~/Documents/PhD-cloudless/Doctoriales.org" "notes")
        "* NOTE %?\n%U" :empty-lines 1)
       ("bw" "Link" entry (file+headline "~/Documents/PhD-cloudless/Doctoriales.org" "Notes") "* %? %^L %^g \n%T" :prepend t)
       ("wa" "Appointment (sync)" entry (file  "gcal-work.org" ) "* %?\n\n%^T\n\n:PROPERTIES:\n\n:END:\n\n")
       ("p" "Personal templates")
       ("pt" "TODO entry" entry
        (file+headline "personal.org" "Capture")
        ( file "tpl_todo.txt" ) :empty-lines-before 1)
       ("pl" "Logbook entry" entry (file+datetree "tagebuechlein.org.gpg") "** %U - %^{Activity}  :LOG:")
       ("pw" "Link" entry (file+headline "personal.org.gpg" "Links") "* %? %^L %^g \n%T" :prepend t)
       ("pn" "Note" entry (file+headline "personal.org.gpg" "Notes")
        "* NOTE %?\n%U" :empty-lines 1)
       ("pN" "Note with Clipboard" entry (file+headline "personal.org.gpg" "Notes")
        "* NOTE %?\n%U\n   %c" :empty-lines 1)
       ("pa" "Appointment (sync)" entry (file  "gcal.org" ) "* %?\n\n%^T\n\n:PROPERTIES:\n\n:END:\n\n")
       ("c" "Cooking Templates")
       ("cw" "Recipe from web" entry (file+headline "Kochbuch.org" "Unkategorisiert") "%(org-chef-get-recipe-from-url)" :empty-lines 1)
       ("cm" "Manual Recipe" entry (file+headline "Kochbuch.org" "Unkategorisiert")
        "* %^{Recipe title: }\n  :PROPERTIES:\n  :source-url:\n  :servings:\n  :prep-time:\n  :cook-time:\n  :ready-in:\n  :END:\n** Ingredients\n   %?\n** Directions\n\n")
       ("d" "Drill")
       ("b" "Business")
       ("df" "French Vocabulary" entry
        (file+headline "drill/french.org" "Vocabulary")
        "* %^{The word} :drill:\n %t\n %^{Extended word (may be empty)} \n** Answer \n%^{The definition}"))
     ))
(after! org
  (setq org-agenda-custom-commands
        '(("c" "Simple agenda view"
           ((agenda "")
            (alltodo ""))))))
(after! org-gcal
  (setq org-gcal-client-id "778561039072-m4jsg3lmr9eoihk79uouuucf9tug9agp.apps.googleusercontent.com"
        org-gcal-client-secret "UjB-Q-S09K2uZjHcoRIyPvNd"
        org-gcal-file-alist '(("naehmlich@gmail.com" .  "~/Documents/org/gcal.org")
                              ("rhcgeikr7l3umo3vk69rbn9nos@group.calendar.google.com" . "~/Documents/org/gcal-work.org")))
                              )
(setq org-log-into-drawer t)
(setq org-log-redeadline (quote note))
(setq org-log-reschedule (quote note))
(setq org-log-repeat (quote note))
(setq org-brain-path "~/Documents/org/brain")
(setq org-brain-visualize-default-choices 'all)
(setq org-brain-title-max-length 12)
(setq org-brain-include-file-entries nil
      org-brain-file-entries-use-title nil)
(require 'ob-async)
(add-to-list 'load-path "~/programs/julia")
(add-to-list 'exec-path "~/programs/julia")
(add-hook 'julia-mode-hook 'julia-repl-mode)
(after! emacs-jupyter
(setq inferior-julia-program-name "/home/philip/programs/julia/julia")
(add-hook 'ob-async-pre-execute-src-block-hook
          '(lambda ()
             (setq inferior-julia-program-name "/home/philip/programs/julia/julia")))
(setq ob-async-no-async-languages-alist '( "jupyter-python" "jupyter-julia" "julia" "python"))
(org-babel-jupyter-override-src-block "python")
;(setq jupyter-pop-up-frame t)
)
(defun jupyter-repl-font-lock-override (_ignore beg end &optional verbose)
  `(jit-lock-bounds ,beg . ,end))

(advice-add #'jupyter-repl-font-lock-fontify-region :override #'jupyter-repl-font-lock-override)
(setq org-confirm-babel-evaluate nil)   ;don't prompt me to confirm everytime I want to evaluate a block
(setq org-babel-default-header-args '((:eval . "never-export") (:results . "replace")))
(org-babel-lob-ingest "~/Documents/org/scripts.org")
(add-to-list 'org-latex-classes
             '("koma-article" "\\documentclass{scrartcl}"
               ("\\section{%s}" . "\\section*{%s}")
               ("\\subsection{%s}" . "\\subsection*{%s}")
               ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
               ("\\paragraph{%s}" . "\\paragraph*{%s}")
               ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
(add-to-list 'org-latex-classes
             '("mimosis"
               "\\documentclass{mimosis}
[NO-DEFAULT-PACKAGES]
[PACKAGES]
[EXTRA]"
               ("\\chapter{%s}" . "\\addchap{%s}")
               ("\\section{%s}" . "\\section*{%s}")
               ("\\subsection{%s}" . "\\subsection*{%s}")
               ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
               ("\\paragraph{%s}" . "\\paragraph*{%s}")
               ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
(setq org-latex-logfiles-extensions (quote ("lof" "lot" "tex" "aux" "idx" "log" "out" "toc" "nav" "snm" "vrb" "dvi" "fdb_latexmk" "blg" "brf" "fls" "entoc" "ps" "spl" "bbl" "pygtex" "pygstyle")))
(setq org-latex-create-formula-image-program 'imagemagick)
(add-to-list 'org-latex-packages-alist '("" "minted" "xcolor" "siunitx" "nicefrac"))
(setq org-latex-listings 'minted)
(setq org-latex-minted-options
  '(("bgcolor" "lightgray") ("linenos" "true") ("style" "tango")))
(setq org-latex-pdf-process (list "latexmk -shell-escape -bibtex -f -pdf %f"))
(use-package! ox-pandoc)
(use-package! org-ref
    :after org
    :init
    ; code to run before loading org-ref
    :config
    ; code to run after loading org-ref
  ;; bibtex
  ;; somehow does not work
  ;;  ;; adjust note style
  ;; (defun my/org-ref-notes-function (candidates)
  ;;   (let ((key (helm-marked-candidates)))
  ;;     (funcall org-ref-notes-function (car key))))
  ;; '(helm-delete-action-from-source "Edit notes" helm-source-bibtex)
  ;; '(helm-add-action-to-source "Edit notes (org-ref)" 'my/org-ref-notes-function helm-source-bibtex 10)

  ;; does not work either
  ;; Tell org-ref to let helm-bibtex find notes for it
  (setq org-ref-notes-function
        (lambda (thekey)
	        (let ((bibtex-completion-bibliography (org-ref-find-bibliography)))
	          (bibtex-completion-edit-notes
	           (list (car (org-ref-get-bibtex-key-and-file thekey)))))))

  (setq org-ref-default-bibliography '("~/Documents/PhD/Literaturebib/library_org.bib")
        org-ref-pdf-directory "~/Documents/PhD/Literature/pdfs/"
        org-ref-bibliography-notes "~/Documents/PhD/Literaturebib/notes.org"
        org-ref-notes-directory "~/Documents/PhD/Literaturebib/notes/"
        reftex-default-bibliography '("~/Documents/PhD/Literaturebib/library_org.bib")
        ;;bibtex-completion-notes "~/Documents/PhD/Literature.bib/notes"
        bibtex-completion-notes-path "~/Documents/PhD/Literaturebib/notes.org"
        bibtex-completion-bibliography "~/Documents/PhD/Literaturebib/library_org.bib"
        bibtex-completion-library-path "~/Documents/PhD/Literature/pdfs")

  (setq bibtex-completion-find-additional-pdfs t)
  (setq org-ref-completion-library 'org-ref-ivy-cite)
  (setq org-ref-show-broken-links t)
  (setq org-latex-prefer-user-labels t)
    )
(use-package! org-noter
  :after (:any org pdf-view)
  :config
   (defun my/org-custom-id-get (&optional pom create prefix)
     "Get the CUSTOM_ID property of the entry at point-or-marker POM.
   If POM is nil, refer to the entry at point. If the entry does
   not have an CUSTOM_ID, the function returns nil. However, when
   CREATE is non nil, create a CUSTOM_ID if none is present
   already. PREFIX will be passed through to `org-id-new'. In any
   case, the CUSTOM_ID of the entry is returned."
     (interactive)
     (org-with-point-at pom
       (let ((id (org-entry-get nil "CUSTOM_ID")))
         (cond
          ((and id (stringp id) (string-match "\\S-" id))
           id)
          (create
           (setq id (org-id-new (concat prefix "h")))
           (org-entry-put pom "CUSTOM_ID" id)
           (org-id-add-location id (buffer-file-name (buffer-base-buffer)))
           id)))))
   (setq org-noter-always-create-frame nil)
   (defun make-noter-from-custom-id (&optional pom create prefix)
     "Get the CUSTOM_ID property of the entry at point-or-marker POM.
   If POM is nil, refer to the entry at point. If the entry does
   not have an CUSTOM_ID, the function returns nil. However, when
   CREATE is non nil, create a CUSTOM_ID if none is present
   already. PREFIX will be passed through to `org-id-new'. In any
   case, the CUSTOM_ID of the entry is returned."
     (interactive)
       (let ((id (org-entry-get (point) "Custom_ID" )))
         (setq pdfpath (concat "../Literature/pdfs/"  id ".pdf"))
           (org-entry-put (point) "NOTER_DOCUMENT" pdfpath)
           ))
  (setq
   ;; The WM can handle splits
   org-noter-notes-window-location 'other-frame
   ;; Please stop opening frames
   org-noter-always-create-frame nil
   ;; I want to see the whole file
   org-noter-hide-other nil
   org-noter-notes-search-path "~/Documents/PhD/Literature.bib/notes"
   )
  )
(use-package! org-sidebar
  :after org-mode
  :config
  (setq org-sidebar-tree-jump-fn #'org-sicebar-tree-jump-source))
(use-package! org-mime)
;; (add-to-list 'load-path "~/programs/beancount/editors/emacs")
  ;; (require 'beancount)
  (after! beancount
  (add-to-list 'auto-mode-alist '("\\.beancount\\'" . beancount-mode))  ;; Automatically open .beancount files in beancount-mode.
  (add-to-list 'auto-mode-alist '("\\.beancount$" . beancount-mode))
  (add-hook 'beancount-mode-hook 'outline-minor-mode))
;; (after! lsp-mode
;;   (use-package! lsp-python-ms
;;     :ensure t
;;     :config
;;     (setq lsp-prefer-capf t)
;;     )
;;   )
;; uncomment to have default interpreter as ipython. in Doom : use +python/open-ipython-repl instead
;; (when (executable-find "ipython")
;;   (setq python-shell-interpreter "ipython"))
;; (use-package! lsp-python-ms
;;   :ensure t
;;   :hook (python-mode . (lambda ()
;;                           (require 'lsp-python-ms)
;;                           (lsp))))
(setq lsp-pyls-server-command '("mspyls"))
;;(setq vc-handled-backends nil)
;;(unpin! t)
(setq auto-save-default t
      auto-save-timeout 10
      auto-save-interval 150)
(setq auto-save-file-name-transforms
  `((".*" "~/.emacs-saves/" t)))
(setq backup-directory-alist `(("." . "~/.emacs-saves")))
(setq backup-by-copying t)
(setq delete-old-versions t
  kept-new-versions 2
  kept-old-versions 0
  version-control t)
(setq vc-make-backup-files t)

(defun force-backup-of-buffer ()
  ;; Make a special "per session" backup at the first save of each
  ;; emacs session.
  (when (not buffer-backed-up)
    ;; Override the default parameters for per-session backups.
    (let ((backup-directory-alist '(("" . "~/.emacs-saves/per-session")))
          (kept-new-versions 3))
      (backup-buffer)))
  ;; Make a "per save" backup on each save.  The first save results in
  ;; both a per-session and a per-save backup, to keep the numbering
  ;; of per-save backups consistent.
  (let ((buffer-backed-up nil))
    (backup-buffer)))

(add-hook 'before-save-hook  'force-backup-of-buffer)
(add-load-path! "/usr/share/emacs/site-lisp/mu4e")
(use-package! mu4e
  :config
(remove-hook 'mu4e-main-mode-hook 'evil-collection-mu4e-update-main-view)
  (load! "mu4e-config.el"))
(use-package!
    snails)
