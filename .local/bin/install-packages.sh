#!/usr/bin/env bash

readonly PKG_LIST_PATH=$HOME/.pkglists

# pacman
if command -v pacman &> /dev/null; then
    sudo pacman -S --needed - < "$PKG_LIST_PATH/arch-official.txt"

    if ! command -v yay &> /dev/null; then
	mkdir -p "$HOME/git"
	git clone https://aur.archlinux.org/yay.git "$HOME/git/yay"
	cd "$HOME/git/yay" || exit 1
	makepkg -si --needed --noconfirm
    fi

    yay -S --needed - < "$PKG_LIST_PATH/arch-aur.txt"
fi

# apt
if command -v apt-mark &> /dev/null; then
    sudo apt install $(cat "$PKG_LIST_PATH/apt.txt")
fi

# homebrew
# brew, brew cask

# snap

# python
python3 -m pip install --user --upgrade --requirement "$PKG_LIST_PATH/pip.txt"
