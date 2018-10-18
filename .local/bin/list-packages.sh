#!/bin/sh
mkdir -p ~/.pkglists
pacman -Qneq > ~/.pkglists/arch-official.txt
pacman -Qmeq > ~/.pkglists/arch-aur.txt

# TODO: make brew also backup -> brew leaves + brew cask list
