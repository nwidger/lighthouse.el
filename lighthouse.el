;;; lighthouse.el --- Integration with Lighthouse via lh utility

;; Copyright (C) 2018 by Niels Widger
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation files
;; (the "Software"), to deal in the Software without restriction,
;; including without limitation the rights to use, copy, modify, merge,
;; publish, distribute, sublicense, and/or sell copies of the Software,
;; and to permit persons to whom the Software is furnished to do so,
;; subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; To use lighthouse.el, install the latest release of the lh utility:
;;
;;     https://github.com/nwidger/lighthouse/releases
;;
;; Or build it from source (requires Go tooling, see
;; https://golang.org/dl):
;;
;;     $ go get -u github.com/nwidger/lighthouse/cmd/lh
;;
;; Then place the following lines into ~/.lh.yaml:
;;
;;     account: <your-lighthouse-account-name>
;;     token: <your-lighthouse-api-token>
;;     project: <your-lighthouse-project-name>
;;
;; Next, copy this file to a directory on your `load-path', and add
;; this to your ~/.emacs:
;;
;;     (add-to-list 'load-path
;;                  "~/.emacs.d/lisp")
;;
;;     (require 'lighthouse)
;;
;; If the lh utility is not in a standard location, you may need to
;; modify `exec-path' in your ~/.emacs:
;;
;;     (add-to-list 'exec-path "/path/to/directory/containing/lh/binary")
;;
;; Next, configure the variables `lighthouse-states' and
;; `lighthouse-assignees' to determine the possible ticket states and
;; assigness:
;;
;;     (setq lighthouse-states '("committed" "new" "open"))
;;     (setq lighthouse-assignees '("Fred" "Bob" "George"))
;;
;; Suggested keybindings:
;;
;;     (global-set-key (kbd "C-c l b") 'lighthouse-browse-ticket)
;;     (global-set-key (kbd "C-c l s") 'lighthouse-ticket-summary)
;;     (global-set-key (kbd "C-c l a") 'lighthouse-ticket-update-assigned)
;;     (global-set-key (kbd "C-c l m") 'lighthouse-ticket-update-milestone)
;;     (global-set-key (kbd "C-c l S") 'lighthouse-ticket-update-state)
;;
;; See https://github.com/nwidger/lighthouse/tree/master/cmd/lh for
;; more information on installing and setting up lh.

;;; Code:

(require 'json)

(defcustom lighthouse-states
  '("committed" "new" "open" "duplicate" "boneyard"
    "resolved" "hold" "invalid")
  "Lighthouse ticket state choices."
  :group 'lighthouse
  :type '(repeat (string)))

(defcustom lighthouse-assignees
  '()
  "Lighthouse ticket assignee choices."
  :group 'lighthouse
  :type '(repeat (string)))

(defun lighthouse-browse-ticket (ticket)
  (interactive (list
                (read-string (format "Ticket (%s): " (thing-at-point 'number))
                             nil nil (thing-at-point 'number))))
  (let ((url (lighthouse-ticket-get-url ticket)))
    (browse-url url)))

(defun lighthouse-ticket-summary (ticket)
  (interactive (list
                (read-string (format "Ticket (%s): " (thing-at-point 'number))
                             nil nil (thing-at-point 'number))))
  (let* ((summary (lighthouse-make-ticket-summary (lighthouse-get-ticket ticket))))
    (message summary)))

(defun lighthouse-ticket-update-assigned (ticket assigned)
  (interactive
   (let* ((num (read-string (format "Ticket (%s): " (thing-at-point 'number))
                           nil nil (thing-at-point 'number)))
          (new (completing-read "Assigned: " lighthouse-assignees nil nil
                                            (lighthouse-ticket-get-assigned num))))
     (list num new)))
  (message (lighthouse-make-ticket-summary
            (lighthouse-ticket-update-field ticket "--assigned" assigned))))

(defun lighthouse-ticket-update-milestone (ticket milestone)
  (interactive
   (let* ((num (read-string (format "Ticket (%s): " (thing-at-point 'number))
                           nil nil (thing-at-point 'number)))
          (new (read-string "Milestone: " (lighthouse-ticket-get-milestone num))))
     (list num new)))
  (message (lighthouse-make-ticket-summary
            (lighthouse-ticket-update-field ticket "--milestone" milestone))))

(defun lighthouse-ticket-update-state (ticket state)
  (interactive
   (let* ((num (read-string (format "Ticket (%s): " (thing-at-point 'number))
                           nil nil (thing-at-point 'number)))
          (new (completing-read "State: " lighthouse-states nil nil
                                            (lighthouse-ticket-get-state num))))
     (list num new)))
  (message (lighthouse-make-ticket-summary
            (lighthouse-ticket-update-field ticket "--state" state))))

(defun lighthouse-parse-ticket (str)
  (let* ((json-object-type 'hash-table)
         (json-array-type 'list)
         (json-key-type 'string))
    (json-read-from-string str)))

(defun lighthouse-get-ticket (ticket)
  (progn
    (if (numberp ticket)
        (setq ticket (number-to-string ticket)))
    (lighthouse-parse-ticket
     (shell-command-to-string (format "lh get ticket %s" ticket)))))

(defun lighthouse-ticket-get-assigned (ticket)
  (interactive (list
                (read-string (format "Ticket (%s): " (thing-at-point 'number))
                             nil nil (thing-at-point 'number))))
  (let ((assigned (lighthouse-ticket-get-field ticket "assigned_user_name")))
    (if (called-interactively-p 'interactive)
        (message assigned)
      assigned)))

(defun lighthouse-ticket-get-description (ticket)
  (interactive (list
                (read-string (format "Ticket (%s): " (thing-at-point 'number))
                             nil nil (thing-at-point 'number))))
  (let ((description (lighthouse-ticket-get-field ticket "title")))
    (if (called-interactively-p 'interactive)
        (message description)
      description)))

(defun lighthouse-ticket-get-milestone (ticket)
  (interactive (list
                (read-string (format "Ticket (%s): " (thing-at-point 'number))
                             nil nil (thing-at-point 'number))))
  (let ((milestone (lighthouse-ticket-get-field ticket "milestone_title")))
    (if (called-interactively-p 'interactive)
        (message milestone)
      milestone)))

(defun lighthouse-ticket-get-state (ticket)
  (interactive (list
                (read-string (format "Ticket (%s): " (thing-at-point 'number))
                             nil nil (thing-at-point 'number))))
  (let ((state (lighthouse-ticket-get-field ticket "state")))
    (if (called-interactively-p 'interactive)
        (message state)
      state)))

(defun lighthouse-ticket-get-url (ticket)
  (interactive (list
                (read-string (format "Ticket (%s): " (thing-at-point 'number))
                             nil nil (thing-at-point 'number))))
  (let ((url (lighthouse-ticket-get-field ticket "url")))
    (if (called-interactively-p 'interactive)
        (message url)
      url)))

(defun lighthouse-ticket-get-field (ticket field)
  (let ((tkt (lighthouse-get-ticket ticket)))
    (gethash field tkt)))

(defun lighthouse-ticket-update-field (ticket flag value)
  (lighthouse-parse-ticket
   (progn
     (if (numberp ticket)
         (setq ticket (number-to-string ticket)))
     (shell-command-to-string (format "lh update ticket %s %s %s" ticket flag value)))))

(defun lighthouse-make-ticket-summary (tkt)
  (format "[#%s title:\"%s\" milestone:\"%s\" state:\"%s\" responsible:\"%s\" reported_by:\"%s\" tagged:\"%s\"]"
          (gethash "number" tkt)
          (gethash "title" tkt)
          (gethash "milestone_title" tkt)
          (gethash "state" tkt)
          (gethash "creator_name" tkt)
          (gethash "assigned_user_name" tkt)
          (gethash "tag" tkt)))

(provide 'lighthouse)
;;; lighthouse.el ends here
