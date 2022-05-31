;;; citre-lang-fileref.el --- Find references of files in file browser -*- lexical-binding: t -*-

;; Copyright (C) 2021 Hao WANG

;; Author: Hao WANG <amaikinono@gmail.com>
;; Maintainer: Hao WANG <amaikinono@gmail.com>
;; Created: 18 Jan 2021
;; Keywords: convenience, tools
;; Homepage: https://github.com/universal-ctags/citre
;; Version: 0.2.1
;; Package-Requires: ((emacs "26.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file supports finding references of the file (or its related
;; module/library) at point in file browser buffers.  Currently only
;; Dired is supported.

;;; Code:

;; To see the outline of this file, run M-x outline-minor-mode and
;; then press C-c @ C-t. To also show the top-level functions and
;; variable declarations in each section, run M-x occur with the
;; following query: ^;;;;* \|^(

;;;; Libraries

(require 'citre-tags)

(declare-function dired-get-filename "dired"
                  (localp no-error-if-not-filep))

;;;; Get symbol at point

(defun citre-lang-fileref-get-symbol ()
  "Get the filename without directory in current line in file browser.
The extension is trimmed, unless it's a header file.  Since in
most \"file-as-module\" languages, the module name is the file
name without extension, but in C, the header file name is used
directly.

When there's an active region, the text inside it is returned, so
if the default behavior is inappropriate, you can mark the module
name part manually."
  (or (citre-tags-get-marked-symbol)
      (when-let ((file (and (derived-mode-p 'dired-mode)
                            (dired-get-filename 'no-dir t))))
        (if (string-match "\\.[^.]*$" file)
            (if (member (match-string 0 file)
                        '(".h" ".hpp"))
                file
              (substring file 0 (match-beginning 0)))
          file))))

;;;; Filter for finding references

;; NOTE: The Citre API and its UI uses the term "finding definitions", but what
;; we really do is finding references.

(defvar citre-lang-fileref-filter
  (citre-readtags-filter 'extras "reference" 'csv-contain
                         ;; We have to keep lines that don't have extras: field
                         ;; because it's not generated by default even with
                         ;; --fields=+r.
                         nil nil 'ignore-missing)
  "Filter for finding references of modules/libraries/headers.")

(defvar citre-lang-fileref-sorter
  (citre-readtags-sorter
   `(filter ,(citre-readtags-filter 'extras "reference" 'csv-contain) +)
   'input '(length name +) 'name)
  "Sorter for finding references of modules/libraries/headers.")

;;;; Plugging into the language support framework

(defvar citre-lang-fileref-plist
  `(:get-symbol
    citre-lang-fileref-get-symbol
    :definition-filter
    citre-lang-fileref-filter
    :definition-sorter
    citre-lang-fileref-sorter)
  "Support for finding reference of files for Citre.
It supports finding references of the file (or its related
module/library) at point in file browser buffers.  Currently only
Dired is supported.")

(citre-tags-register-language-support 'dired-mode citre-lang-fileref-plist)

(provide 'citre-lang-fileref)

;; Local Variables:
;; indent-tabs-mode: nil
;; outline-regexp: ";;;;* "
;; fill-column: 79
;; emacs-lisp-docstring-fill-column: 65
;; sentence-end-double-space: t
;; End:

;;; citre-lang-fileref.el ends here
