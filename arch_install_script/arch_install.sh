#!/usr/bin/bash

#########################################################################################
# arch_install.sh
#
# arch installation guide: https://wiki.archlinux.org/index.php/installation_guide
#
# please follow the arch linux installation guide. this script is my own way to install
# but be warned that it WILL become outdated
#
# installs arch linux using the following:
# - disks:
#   - GPT
#   - dm-crypt: LUKS on a partition
#   - efi: /efi + /boot using bind mount
#########################################################################################

set -e
set -x

SETUP_DEVICE=/dev/sda
# SETUP_DEVICE=/dev/nvme0n1

# update the system clock
timedatectl set-ntp true

# partition the disks
parted $SETUP_DEVICE --align optimal \
       mklabel gpt \
       mkpart ESP fat32 1MiB 1000MiB \
       set 1 esp on \
       mkpart root 1000MiB 100%
# encrypt partition: LVM on LUKS
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
echo "encrypting disk: /dev/disk/by-partlabel/root"
cryptsetup -y -v luksFormat --type luks2 /dev/disk/by-partlabel/root
cryptsetup open /dev/disk/by-partlabel/root cryptroot

# setup lvm
pvcreate /dev/mapper/cryptroot
vgcreate vg0 /dev/mapper/cryptroot
lvcreate -L 32G vg0 -n root
lvcreate -l 100%FREE vg0 -n home

# format the partitions
mkfs.fat -F32 /dev/disk/by-partlabel/ESP
mkfs.ext4 /dev/vg0/root
mkfs.ext4 /dev/vg0/home

# mount partitions
mount /dev/vg0/root /mnt
mkdir /mnt/home
mount /dev/vg0/home /mnt/home
# https://wiki.archlinux.org/index.php/EFI_system_partition#Using_bind_mount
mkdir /mnt/efi /mnt/boot
mount /dev/disk/by-partlabel/ESP /mnt/efi
mkdir /mnt/efi/arch
mount --bind /mnt/efi/arch /mnt/boot

# install arch base and essential packages
pacstrap /mnt \
         base \
         binutils \
         fakeroot \
         git \
         lvm2 \
         make \
         patch \
         sudo

# configure fstab
genfstab -t PARTLABEL /mnt >> /mnt/etc/fstab
sed -i 's,/mnt,,g' /mnt/etc/fstab

# configure arch in chroot
cp arch_install_chroot.sh /mnt/root/
arch-chroot /mnt /root/arch_install_chroot.sh
rm /mnt/root/arch_install_chroot.sh

read -r -p "Press [Enter] to reboot: "

# systemd-resolved: make /etc/resolv.conf point to the systemd DNS stub file
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
mv /etc/resolv.conf /mnt/etc/resolv.conf

# exit
umount -R /mnt
lvchange --activate n vg0
cryptsetup close cryptroot
systemctl reboot
