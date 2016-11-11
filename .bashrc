# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoredups:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=100000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# use 256 color terminal (for emacs' themes)
export TERM=xterm-256color

# use emacs
export ALTERNATE_EDITOR='' # for emacs --daemon
export EDITOR='emacsclient -nw'
export VISUAL='emacsclient -nw'
export GIT_EDITOR='emacsclient -nw'

# setup PS1 with git
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUPSTREAM=1
export GIT_PS1_SHOWCOLORHINTS=1
PROMPT_COMMAND='__git_ps1 "\[\033[01;34m\]\w\[\033[00m\]" "\[\033[01;36m\]$\[\033[00m\] "'
# Save and reload the history after each command finishes
# PROMPT_COMMAND="history -n; history -w; history -c; history -r; $PROMPT_COMMAND"

# load project related scripts
if [ -f $HOME/savetyping.sh ]; then
    . $HOME/savetyping.sh
fi

# Add RVM to PATH for scripting
export PATH="$PATH:$HOME/.rvm/bin:$HOME/.rbenv/bin"
export GOPATH="$HOME/go"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

################################################################################
# backup config settings
################################################################################
backup_dotfiles()
{
    local conf_files=(
        "$HOME/.ackrc"
        "$HOME/.bash_aliases"
        "$HOME/.bashrc"
        "$HOME/.cgdb/"
        "$HOME/.gdbinit"
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
    )

    for i in "${conf_files[@]}"
    do
        cp -r $i $HOME/Dropbox/utils/config_backup/
        cp -r $i $HOME/git/dotfiles/
    done
}
export -f backup_dotfiles
alias backup_config='backup_dotfiles'
