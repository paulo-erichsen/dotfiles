# dotfiles

This is a small collection of [dotfiles](https://dotfiles.github.io/) and scripts that I personally use

Normally when I setup a new system, I setup my [dotfiles](https://github.com/paulohefagundes/dotfiles), [emacs](https://github.com/paulohefagundes/.emacs.d),  and [firefox](https://github.com/paulohefagundes/user.js)

## dotfiles setup

### linux / macOS

`git clone` this repository, `cd` into it, then run `bash install` to automatically setup the environment with the dotfiles

``` bash
git clone git@github.com:paulohefagundes/dotfiles.git ~/git/dotfiles
bash ~/git/dotfiles/install
```

### windows

TODO: add commands for symbolic links in WindowsPowerShell/

## environment setup

These are automated scripts for setting up environments for my needs

### linux

TODO: add shell script for installing stuff (pacman / apt)

### macOS

#### set macOS defaults

```
# TODO: add automated script for setting up macOS defaults
```

#### install Homebrew formulae

``` bash
brew.sh # installs homebrew and many programs that I normally use
```

### windows

Open PowerShell and type these commands. This will install many packages through [boxstarter](http://boxstarter.org/) and [chocolatey](https://chocolatey.org/)

``` powershell
Set-ExecutionPolicy Unrestricted -Force
. { iwr -useb http://boxstarter.org/bootstrapper.ps1 } | iex; get-boxstarter -Force
Install-BoxstarterPackage -PackageName https://raw.githubusercontent.com/paulohefagundes/dotfiles/master/WindowsPowerShell/boxstarter.ps1
```

## Acknowledgements
* MacOS - https://github.com/mathiasbynens/dotfiles
* MacOS - https://github.com/donnemartin/dev-setup
* Windows - https://github.com/W4RH4WK/Debloat-Windows-10
* [dotbot](https://github.com/anishathalye/dotbot)

## TODO
* split many chocolatey programs from the main boxstarter
