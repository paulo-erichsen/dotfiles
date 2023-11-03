#!/usr/bin/bash

#########################################################################################
# arch_fix_boot.sh
#
# reinstalls systemd-boot into the EFI
#########################################################################################

set -e
set -x

# unlock
cryptsetup open /dev/disk/by-partlabel/root cryptroot

# mount
mount_opts=noatime,compress=zstd,x-mount.mkdir
mount -o $mount_opts,subvol=@          /dev/mapper/cryptroot /mnt
mount -o $mount_opts,subvol=@home      /dev/mapper/cryptroot /mnt/home
mount -o $mount_opts,subvol=@log       /dev/mapper/cryptroot /mnt/var/log
mount -o $mount_opts,subvol=@pkg       /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
mount -o $mount_opts,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount -o $mount_opts,subvol=/          /dev/mapper/cryptroot /mnt/btrfs
mkdir -p /mnt/efi /mnt/boot
mount /dev/disk/by-partlabel/ESP /mnt/efi
mount --bind /mnt/efi/arch /mnt/boot

# bootctl install
arch-chroot /mnt bootctl --esp-path /efi install

read -r -p "Press [Enter] to reboot: "

# exit
umount -R /mnt
cryptsetup close cryptroot
systemctl reboot
