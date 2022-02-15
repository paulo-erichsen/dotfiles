# arch install script

the script in this directory automates some of the steps I use to install Arch Linux.

even though I've automated these, it is recommended that you follow the Arch Linux [Installation Guide]

## install steps

1. download the latest image from the [Download] page

### if using Virtual Box

- create a disk of at least 40 GB
- settings > system > motherboard > 8GB of RAM
- settings > system > Enable EFI
- settings > storage > select SATA drive > check Solid State Drive in attributes (if the host machine also uses SSD)
- boot machine, select optical drives > path to archlinux-*.iso

### if using Host machine

- [create boot usb drive]

### download and run this script

```
# download through curl
curl -O https://raw.githubusercontent.com/paulo-erichsen/dotfiles/master/arch_install_script/arch_install.sh
curl -O https://raw.githubusercontent.com/paulo-erichsen/dotfiles/master/arch_install_script/arch_install_chroot.sh
chmod +x arch_install*.sh

# then edit the script if you need to tweak anything

# run the script from within archiso
./arch_install.sh
```

[Installation Guide]: https://wiki.archlinux.org/index.php/Installation_guide
[Download]: https://www.archlinux.org/download/
[create boot usb drive]: https://askubuntu.com/a/377561
