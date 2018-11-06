#!/usr/bin/env bash

readonly PKG_LIST_PATH=$HOME/.pkglists

# pacman
if command -v pacman &> /dev/null; then
    sudo pacman -S --needed - < "$PKG_LIST_PATH/arch-official.txt"

    # TODO: install yay, aur packages through yay
fi

# apt
if command -v apt-mark &> /dev/null; then
    sudo apt install $(cat "$PKG_LIST_PATH/apt.txt")
fi

# homebrew
# brew, brew cask

# snap

# python
python3 -m pip install --user --requirement "$PKG_LIST_PATH/pip.txt"
