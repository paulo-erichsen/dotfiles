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

SETUP_DEVICE=/dev/nvme0n1 # /dev/sda
SETUP_SCHEME=btrfs-on-luks # allowed values: lvm-on-luks, btrfs-on-luks

# validate params
if [[ ! "$SETUP_SCHEME" =~ ^(lvm-on-luks|btrfs-on-luks)$ ]]; then
    echo "invalid SETUP_SCHEME: $SETUP_SCHEME"
    exit 1
fi
if [ ! -b $SETUP_DEVICE ]; then
    echo "device doesn't exist: $SETUP_DEVICE"
    exit 1
fi

# update the system clock
timedatectl set-ntp true

# partition the disks
parted $SETUP_DEVICE mklabel gpt
parted $SETUP_DEVICE --align optimal \
       mkpart ESP fat32 1MiB 1000MiB \
       set 1 esp on \
       mkpart root 1000MiB 100%

# encrypt partition
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system
echo "encrypting disk: /dev/disk/by-partlabel/root"
cryptsetup -y -v luksFormat --type luks2 /dev/disk/by-partlabel/root
cryptsetup open /dev/disk/by-partlabel/root cryptroot

if [ "$SETUP_SCHEME" = "lvm-on-luks" ]; then
    EXTRA_INSTALL_PKGS=lvm2

    # setup lvm
    pvcreate /dev/mapper/cryptroot
    vgcreate vg0 /dev/mapper/cryptroot
    lvcreate -L 32G vg0 -n root
    lvcreate -l 100%FREE vg0 -n home

    # format the partitions
    mkfs.ext4 /dev/vg0/root
    mkfs.ext4 /dev/vg0/home

    # mount partitions
    mount /dev/vg0/root /mnt
    mkdir /mnt/home
    mount /dev/vg0/home /mnt/home
elif [ "$SETUP_SCHEME" = "btrfs-on-luks" ]; then
    EXTRA_INSTALL_PKGS="btrfs-progs snapper"

    # format the partition as btrfs
    mkfs.btrfs --label system /dev/mapper/cryptroot
    mount -t btrfs /dev/mapper/cryptroot /mnt

    # create the subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var_log
    btrfs subvolume create /mnt/@pkg
    btrfs subvolume create /mnt/@snapshots

    # mount the subvolumes
    umount /mnt
    mount_opts=noatime,compress=zstd,x-mount.mkdir
    mount -o $mount_opts,subvol=@          /dev/mapper/cryptroot /mnt
    mount -o $mount_opts,subvol=@home      /dev/mapper/cryptroot /mnt/home
    mount -o $mount_opts,subvol=@var_log   /dev/mapper/cryptroot /mnt/var/log
    mount -o $mount_opts,subvol=@pkg       /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
    mount -o $mount_opts,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
    mount -o $mount_opts,subvol=/          /dev/mapper/cryptroot /mnt/btrfs

    chattr +C /mnt/var/log # disable CoW on @var_log
fi

# https://wiki.archlinux.org/index.php/EFI_system_partition#Using_bind_mount
mkfs.fat -F32 /dev/disk/by-partlabel/ESP
mkdir -p /mnt/efi /mnt/boot
mount /dev/disk/by-partlabel/ESP /mnt/efi
mkdir /mnt/efi/arch
mount --bind /mnt/efi/arch /mnt/boot

# install arch base and essential packages
pacstrap /mnt \
         base \
         binutils \
         fakeroot \
         git \
         make \
         patch \
         sudo \
         $EXTRA_INSTALL_PKGS

# configure fstab
genfstab -t PARTLABEL /mnt >> /mnt/etc/fstab
sed -i 's,/mnt,,g' /mnt/etc/fstab # bind mount needs extra care
if [ "$SETUP_SCHEME" = "btrfs-on-luks" ]; then
    sed -i 's;subvol=/\t;subvol=/,noauto\t;' /mnt/etc/fstab # don't automatically mount /btrfs
    sed -i 's;subvolid=[[:digit:]]\+,;;' /mnt/etc/fstab # remove subvolid= see also https://bugs.archlinux.org/task/65003 for a related bug
fi

# configure arch in chroot
cp arch_install_chroot.sh /mnt/root/
arch-chroot /mnt /root/arch_install_chroot.sh --scheme $SETUP_SCHEME
rm /mnt/root/arch_install_chroot.sh

read -r -p "Press [Enter] to reboot: "

# systemd-resolved: make /etc/resolv.conf point to the systemd DNS stub file
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
mv /etc/resolv.conf /mnt/etc/resolv.conf

# exit
umount -R /mnt
if [ "$SETUP_SCHEME" = "lvm-on-luks" ]; then
    lvchange --activate n vg0
fi
cryptsetup close cryptroot
systemctl reboot
