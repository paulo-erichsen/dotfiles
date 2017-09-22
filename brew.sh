#!/usr/bin/env bash

#
# a lot of this was modified to my needs from the following
# - https://github.com/mathiasbynens/dotfiles/blob/master/brew.sh
# - https://github.com/donnemartin/dev-setup/blob/master/brew.sh
#

# install homebrew
if test ! $(which brew); then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew analytics off
brew update
brew upgrade

# GNU and utilities
brew install coreutils # Don't forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install moreutils
brew install findutils  # Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install gnu-sed --with-default-names # overwrite the built-in `sed`
brew install bash # bash4
brew install bash-completion2
# We installed the new shell, now we have to activate it
if ! grep -q '/usr/local/bin/bash' /etc/shells; then
    echo "Adding the newly installed shell to the list of allowed shells"
    sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
    chsh -s /usr/local/bin/bash
fi
brew install wget --with-iri # Install `wget` with IRI support
brew install gnupg # Install GnuPG to enable PGP-signing commits

# Install more recent versions of some macOS tools.
brew install vim --override-system-vi
brew install grep
brew install openssh
brew install screen

# python
brew install python
brew install python3
pip3 install --upgrade pip setuptools wheel

# ruby
# Install ruby-build and rbenv
brew install ruby-build
brew install rbenv
LINE='eval "$(rbenv init -)"'
grep -q "$LINE" ~/.extra || echo "$LINE" >> ~/.extra

# Install other userful binaries.
brew install git
brew install ripgrep
brew install lua
brew install ssh-copy-id
brew install tree

# Install GUI apps
brew cask install firefox # you could choose google-chrome or something else
brew cask install iterm2
brew cask install p4v # perforce
brew cask install dropbox
brew cask install virtualbox

# emacs
# remove the old OS X default emacs (requires disabling system integrity)
sudo rm /usr/bin/emacs*
sudo rm -rf /usr/share/emacs/
brew install emacs # if you'd like the GUI, install `brew cask install emacs` instead. I prefer the command-line though

# emacs key setup
# macOS: System Preferences > Keyboard > Shortcuts > Mission Control > Uncheck C-Up, C-Down, C-Left, C-Right
# iterm2: Preferences > Profiles > Keys > choose Left Option Key acts as: +Esc
# iterm2: Preferences > Profiles > Keys >  Load Preset: Natural Text Editing
# terminal: Preferences > Profiles > Keyboard > Use Option as Meta Key

# Remove outdated versions from the cellar
brew cleanup
