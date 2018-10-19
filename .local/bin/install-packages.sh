#!/bin/sh
sudo pacman -S --needed - < ~/.pkglists/arch-official.txt

# TODO: implement this script
# - it should:
# if arch-linux, install arch-official, yay, aur packages through yay
# if macos, install brew and the brew packages and brew cask packages
# python: something like
# python3 -m pip install --user flake8 mypy pylint numpy matplotlib black virtualenv virtualenvwrapper
# see an example of different packages to be installed - https://github.com/hugdru/dotfiles
#   such as ruby (gem), python (pip), javascript (npm), arch (pacman), etc...
