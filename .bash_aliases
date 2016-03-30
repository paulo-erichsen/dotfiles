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
alias sync_fork='git co master; git up; git fetch upstream --prune; git merge upstream/master && git submodule update --init'
alias my_commits='git log --author="$(git config user.name)" --branches=* --decorate --oneline'
alias backgrounds='sudo cp -r ~/Dropbox/images/backgrounds/ /usr/share/ && sudo chmod -R +r /usr/share/backgrounds/'

# virtual box module needs to be rebuilt when a new kernel is installed
# alias fix_virtual_box='sudo /etc/init.d/vboxdrv setup'
# alias fix_nvidia='sudo dpkg-reconfigure nvidia-331 && sudo dpkg-reconfigure nvidia-331-uvm' # to fix it when kernels are changed
