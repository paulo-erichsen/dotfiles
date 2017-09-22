#
# a lot of this was modified to my needs from
# https://github.com/donnemartin/dev-setup/blob/master/brew.sh
#

# install homebrew
if test ! $(which brew); then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew analytics off
brew update
brew upgrade --all

# GNU and utilities
brew install coreutils # Don't forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install moreutils
brew install findutils  # Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install gnu-sed --with-default-names # overwrite the built-in `sed`
brew install bash # bash4
brew install bash-completion2
# We installed the new shell, now we have to activate it
echo "Adding the newly installed shell to the list of allowed shells"
sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
chsh -s /usr/local/bin/bash
# Install more recent versions of some OS X tools.
brew install vim --override-system-vi
brew install homebrew/dupes/grep
brew install homebrew/dupes/openssh
brew install homebrew/dupes/screen
brew install git
brew install ripgrep

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

# gui apps
brew cask install firefox # you could choose google-chrome or something else
brew cask install iterm2
brew cask install p4v # perforce
brew cask install dropbox
brew cask install virtualbox

# emacs
# remove the old OS X default emacs (requires disabling system integrity)
sudo rm /usr/bin/emacs*
sudo rm -rf /usr/share/emacs

brew install emacs # if you'd like the GUI, install `brew cask install emacs` instead. I prefer the command-line though

# emacs key setup
# macOS: System Preferences > Keyboard > Shortcuts > Mission Control > Uncheck C-Up, C-Down, C-Left, C-Right
# iterm2: Preferences > Profiles > Keys > choose Left Option Key acts as: +Esc
# iterm2: Preferences > Profiles > Keys >  Load Preset: Natural Text Editing
# terminal: Preferences > Profiles > Keyboard > Use Option as Meta Key
