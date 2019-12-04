#!/usr/bin/env bash

###############################################################################
# setup_gnome_settings.sh - sets some gnome configuration that I use
###############################################################################
# gtk-theme: arc-dark (depends on arc-gtk-theme)
gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'

# terminal font: inconsolata-g for powerline (depends on aur: powerline-fonts-git)
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")/" font 'Inconsolata-g for Powerline Medium 11'

# favorite-apps (depends on firefox, chromium, gnome-terminal)
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'firefox.desktop', 'chromium.desktop', 'org.gnome.Terminal.desktop']"

# media keys
gsettings set org.gnome.settings-daemon.plugins.media-keys next "['<Primary><Alt>n']"
gsettings set org.gnome.settings-daemon.plugins.media-keys play "['<Primary><Alt>p']"
gsettings set org.gnome.settings-daemon.plugins.media-keys previous "['<Primary><Alt>b']"
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down "['<Primary><Alt>minus']"
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute "['<Primary><Alt>period']"
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up "['<Primary><Alt>equal']"
