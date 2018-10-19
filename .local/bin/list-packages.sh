#!/bin/bash
mkdir -p ~/.pkglists

readonly PKG_LIST_PATH=$HOME/.pkglists

if command -v pacman &> /dev/null; then
    pacman -Qneq > "$PKG_LIST_PATH/arch-official.txt"
    pacman -Qmeq > "$PKG_LIST_PATH/arch-aur.txt"
fi

if command -v brew &> /dev/null; then
    brew leaves > "$PKG_LIST_PATH/brew.txt"
    brew cask list | sort > "$PKG_LIST_PATH/brew_cask.txt"
fi
