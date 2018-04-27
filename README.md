# lighthouse.el
Emacs integration with Lighthouse via lh utility

To use lighthouse.el, install the latest release of the lh utility:

https://github.com/nwidger/lighthouse/releases

Or build it from source (requires Go tooling, see
https://golang.org/dl):

    $ go get -u github.com/nwidger/lighthouse/cmd/lh

Then place the following lines into ~/.lh.yaml:

    account: <your-lighthouse-account-name>
    token: <your-lighthouse-api-token>
    project: <your-lighthouse-project-name>

Next, copy this file to a directory on your `load-path`, and add
this to your ~/.emacs:

    (add-to-list 'load-path
                 "~/.emacs.d/lisp")

    (require 'lighthouse)

If the lh utility is not in a standard location, you may need to
modify `exec-path` in your ~/.emacs:

    (add-to-list 'exec-path "/path/to/directory/containing/lh/binary")

Next, configure the variables `lighthouse-states` and
`lighthouse-assignees` to determine the possible ticket states and
assigness:

    (setq lighthouse-states '("committed" "new" "open"))
    (setq lighthouse-assignees '("Fred" "Bob" "George"))

Suggested keybindings:

    (global-set-key (kbd "C-c l b") 'lighthouse-browse-ticket)
    (global-set-key (kbd "C-c l s") 'lighthouse-ticket-summary)
    (global-set-key (kbd "C-c l a") 'lighthouse-ticket-update-assigned)
    (global-set-key (kbd "C-c l m") 'lighthouse-ticket-update-milestone)
    (global-set-key (kbd "C-c l S") 'lighthouse-ticket-update-state)

See https://github.com/nwidger/lighthouse/tree/master/cmd/lh for
more information on installing and setting up lh.
