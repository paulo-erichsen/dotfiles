#!/bin/sh
sudo pacman -S --needed - < ~/.pkglists/arch-official.txt

# TODO: implement this script
# - it should:
# if arch-linux, install arch-official, yay, aur packages through yay
# if macos, install brew and the brew packages and brew cask packages
