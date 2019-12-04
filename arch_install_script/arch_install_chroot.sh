#!/usr/bin/bash

set -e # TODO: remove me

# TODO: bounce out of this script if it wasn't called by arch_install.sh

SETUP_TIMEZONE=America/Denver
SETUP_HOSTNAME=arch-pc
SETUP_USER=paulo

# timezone, locale, hostname
ln -sf /usr/share/zoneinfo/$SETUP_TIMEZONE /etc/localtime
hwclock --systohc
grep -E "^en_US.UTF-8 UTF-8" /etc/locale.gen || echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=us > /etc/vconsole.conf
echo "$SETUP_HOSTNAME" > /etc/hostname
cat >> /etc/hosts <<EOF
127.0.0.1      localhost
::1            localhost
127.0.0.1      $SETUP_HOSTNAME
EOF

# modify /etc/mkinitcpio.conf - https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio
sed -i 's/^\(HOOKS=\).*$/\1(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# systemd-boot
bootctl --path /efi install

if lscpu | grep -q GenuineIntel; then
    SETUP_CPU_UCODE=intel-ucode
elif lscpu | grep -q AuthenticAMD; then
    SETUP_CPU_UCODE=amd-ucode
fi

if [[ -v SETUP_CPU_UCODE ]]; then
    pacman -S --noconfirm $SETUP_CPU_UCODE
fi

cat > /efi/loader/loader.conf <<EOF
# timeout 4
default arch
EOF

# TODO: pass SETUP_DEVICE variable instead of hard-coding sda2
SETUP_DISK_UUID=$(blkid -s UUID -o value /dev/sda2)
cat > /efi/loader/entries/arch.conf <<EOF
title  arch linux
linux  /arch/vmlinuz-linux
initrd /arch/$SETUP_CPU_UCODE.img
initrd /arch/initramfs-linux.img
options rd.luks.name=$SETUP_DISK_UUID=cryptroot root=/dev/mapper/cryptroot rw
EOF

# systemd-networkd
cat > /etc/systemd/network/20-wired.network <<EOF
[Match]
Name=en*

[Network]
DHCP=ipv4
EOF

systemctl enable systemd-resolved.service
systemctl enable systemd-networkd.service

# create a new user
useradd --create-home --shell /bin/bash $SETUP_USER
echo "$SETUP_USER:default" | chpasswd # set a default password such that we can use sudo for now, we will expire it later
echo "$SETUP_USER ALL=(ALL) ALL" >> /etc/sudoers

###### user specific config
# install reflector first to allow fast downloads
pacman -S --noconfirm reflector
if command -v reflector > /dev/null; then
    reflector --verbose --latest 64 --number 16 --age 24 --protocol https --country 'United States' --sort rate --save /etc/pacman.d/mirrorlist
fi

pacman -Syu --noconfirm
pacman -S --noconfirm --needed \
       emacs-nox \
       fakeroot \
       git \
       gnome \
       make \
       nvidia \
       patch \
       sudo \
       systemd-swap
# TODO: go over of list of gnome packages and only install the ones I really need
# TODO: add functionality to auto detect nvidia vs amd for pacman

# systemd-swap
sed -i 's/swapfc_enabled=0/swapfc_enabled=1/' /etc/systemd/swap.conf
sed -i 's/swapfc_force_preallocated=0/swapfc_force_preallocated=1/' /etc/systemd/swap.conf
systemctl enable systemd-swap.service
systemctl enable gdm.service # gnome display manager

# install dotfiles, and packages it lists
echo "installing dotfiles and packages for user: $SETUP_USER"
su $SETUP_USER <<EOF
set -e
git clone https://github.com/paulohefagundes/dotfiles.git ~/git/dotfiles
~/git/dotfiles/install
~/git/dotfiles/.local/bin/install-packages.sh

# enable a couple of services for the user
mkdir -p ~/.config/systemd/user/default.target.wants
# systemctl --user enable emacs.service
ln -s /usr/lib/systemd/user/emacs.service  ~/.config/systemd/user/default.target.wants/emacs.service

# systemctl --user enable syncthing.service
ln -s  /usr/lib/systemd/user/syncthing.service ~/.config/systemd/user/default.target.wants/syncthing.service
EOF

# lock the root password and expire the user's password
echo 'locking the root account'
passwd --lock root
echo "expiring the password for user: $SETUP_USER"
passwd --expire $SETUP_USER
