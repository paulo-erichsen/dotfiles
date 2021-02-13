#!/usr/bin/env bash

# TODO: move from ~/.pkglists to $XDG_DATA_HOME
readonly PKG_LIST_PATH=$HOME/.pkglists

# pacman
if command -v pacman &> /dev/null; then
    sudo pacman -S --needed --noconfirm - < "$PKG_LIST_PATH/arch-official.txt"

    if ! command -v paru &> /dev/null; then
        tmp_dir="/tmp/paru-bin-aur"
        [ ! -d "${tmp_dir}" ] && git clone https://aur.archlinux.org/paru-bin.git "${tmp_dir}"
        (cd "${tmp_dir}" && makepkg -sri --needed --noconfirm)
    fi

    paru -S --needed --noconfirm - < "$PKG_LIST_PATH/arch-aur.txt"
fi

# apt
if command -v apt-mark &> /dev/null; then
    sudo apt install $(cat "$PKG_LIST_PATH/apt.txt")
fi

# homebrew
# brew, brew cask

# flatpak

# snap

# python
python3 -m pip install --user --upgrade --requirement "$PKG_LIST_PATH/pip.txt"
