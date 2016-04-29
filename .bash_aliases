# editor aliases
alias e='emacsclient -nw'
alias vim='e'
alias vi='e'
alias kill_emacs='emacsclient -e "(kill-emacs)"' # kills the emacs server

# apt-get aliases
alias updateallthethings='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y'
alias update_all_the_things='updateallthethings'
alias cleanupallthethings='echo "Cleaning Up" &&
      sudo apt-get -f install &&
      sudo apt-get autoremove &&
      sudo apt-get -y autoclean &&
      sudo apt-get -y clean'
alias cleanup_all_the_things='cleanupallthethings'

# git aliases
alias d='git diff -w'
alias log='git log --name-status --date=local'
alias my_commits='git log --author="$(git config user.name)" --branches=* --decorate --oneline'

# misc...
# copy my backgrounds from dropbox for wallch
alias backgrounds='sudo cp -r ~/Dropbox/images/backgrounds/ /usr/share/ && sudo chmod -R +r /usr/share/backgrounds/'
alias open='xdg-open'
alias ack='ack-grep --pascal --ruby'
alias ag="ag --ruby --fpc --color-line-number='1;36' --color-match='45'" # --fpc depends on https://github.com/ggreer/the_silver_searcher/pull/889
