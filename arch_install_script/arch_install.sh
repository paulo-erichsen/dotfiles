#!/usr/bin/bash

set -e # TODO: remove me

SETUP_DEVICE=sda

# fix the date in case we are in an older vm
timedatectl set-ntp true
mount -o remount,size=1G /run/archiso/cowspace # increase cowspace partition

# create efi partition 1GB # TODO: reduce the size of this
parted /dev/$SETUP_DEVICE mklabel gpt
parted /dev/$SETUP_DEVICE mkpart ESP fat32 1MiB 1000MiB
mkfs.fat -F32 /dev/${SETUP_DEVICE}1
parted /dev/$SETUP_DEVICE set 1 boot on
parted /dev/$SETUP_DEVICE mkpart primary 1000MiB 100%

# TODO: maybe add LVM support?

# luks encrypt /dev/sda2
echo "encrypting disk: /dev/${SETUP_DEVICE}2"
cryptsetup -y -v luksFormat --type luks2 /dev/${SETUP_DEVICE}2
cryptsetup open /dev/${SETUP_DEVICE}2 cryptroot
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt

# prepare the boot partition
# https://wiki.archlinux.org/index.php/EFI_system_partition#Using_bind_mount
mkdir /mnt/efi
mount /dev/${SETUP_DEVICE}1 /mnt/efi
mkdir /mnt/efi/arch

# update the mirrorlist
curl --silent "https://www.archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm archlinux-keyring

# install arch base and other packages
pacstrap /mnt base linux # linux-firmware
mv /mnt/boot/* /mnt/efi/arch/
mount --bind /mnt/efi/arch /mnt/boot
genfstab -U /mnt >> /mnt/etc/fstab
sed -i 's,/mnt,,g' /mnt/etc/fstab

# configure arch
cp arch_install_chroot.sh /mnt/root/
arch-chroot /mnt /root/arch_install_chroot.sh
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
mv /etc/resolv.conf /mnt/etc/resolv.conf
rm /mnt/root/arch_install_chroot.sh

# exit
umount -R /mnt
cryptsetup close cryptroot
read -r -p "Press [Enter] to reboot: "
systemctl reboot
