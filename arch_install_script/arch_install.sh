#!/usr/bin/bash

set -e # TODO: remove me
set -x

SETUP_DEVICE=/dev/sda
# SETUP_DEVICE=/dev/nvme0n1

# fix the date in case we are in an older vm
timedatectl set-ntp true
mount -o remount,size=1G /run/archiso/cowspace # increase cowspace partition

# partitions
parted $SETUP_DEVICE mklabel gpt
parted $SETUP_DEVICE mkpart ESP fat32 1MiB 1000MiB
parted $SETUP_DEVICE set 1 boot on
parted $SETUP_DEVICE mkpart root 1000MiB 100%

# TODO: maybe add LVM support?

# luks encrypt
echo "encrypting disk: /dev/disk/by-partlabel/root"
cryptsetup -y -v luksFormat --type luks2 /dev/disk/by-partlabel/root
cryptsetup open /dev/disk/by-partlabel/root cryptroot

# format partitions
mkfs.fat -F32 /dev/disk/by-partlabel/ESP
mkfs.ext4 /dev/mapper/cryptroot

# prepare the boot partition
# https://wiki.archlinux.org/index.php/EFI_system_partition#Using_bind_mount
mount /dev/mapper/cryptroot /mnt
mkdir /mnt/efi
mount /dev/disk/by-partlabel/ESP /mnt/efi
mkdir /mnt/efi/arch

# update the mirrorlist
curl --fail --silent --location "https://archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist
if ! pacman -Sy --noconfirm archlinux-keyring; then
    echo "keyserver hkp://keyserver.ubuntu.com" >> /etc/pacman.d/gnupg/gpg.conf
    pacman-key --refresh-keys || true
    pacman -Sy --noconfirm archlinux-keyring
fi

# install arch base and other packages
if ! pacstrap /mnt base linux; then
    pacman -Sy --noconfirm pacman # workaround if pacman is too old
    pacstrap /mnt base linux
fi
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
