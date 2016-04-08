alias e='emacs -nw'
alias vim='e'
alias vi='e'
alias open='xdg-open'
alias ack='ack-grep --pascal --ruby'
alias updateallthethings='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y'
alias update_all_the_things='updateallthethings'
alias cleanupallthethings='echo "Cleaning Up" &&
      sudo apt-get -f install &&
      sudo apt-get autoremove &&
      sudo apt-get -y autoclean &&
      sudo apt-get -y clean'
alias cleanup_all_the_things='cleanupallthethings'
alias d='git diff -w'
alias log='git log --name-status --date=local'
alias my_commits='git log --author="$(git config user.name)" --branches=* --decorate --oneline'
# copy my backgrounds from dropbox for wallch
alias backgrounds='sudo cp -r ~/Dropbox/images/backgrounds/ /usr/share/ && sudo chmod -R +r /usr/share/backgrounds/'
