#!/bin/bash
mkdir -p ~/.pkglists

readonly PKG_LIST_PATH=$HOME/.pkglists

# pacman
if command -v pacman &> /dev/null; then
    pacman -Qneq > "$PKG_LIST_PATH/arch-official.txt"
    pacman -Qmeq > "$PKG_LIST_PATH/arch-aur.txt"
fi

# homebrew
if command -v brew &> /dev/null; then
    brew leaves > "$PKG_LIST_PATH/brew.txt"
    brew cask list | sort > "$PKG_LIST_PATH/brew_cask.txt"
fi

# apt
if command -v apt-mark &> /dev/null; then
    # https://askubuntu.com/a/492343
    comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) > "$PKG_LIST_PATH"/apt.txt
fi

# snap
# snap list

# pip
# python3 -m pip list --user
