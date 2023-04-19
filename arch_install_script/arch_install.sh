#!/usr/bin/bash

#########################################################################################
# arch_install.sh
#
# arch installation guide: https://wiki.archlinux.org/index.php/installation_guide
#
# please follow the arch linux installation guide.
# this script is my own way to install but be warned that it WILL become outdated.
# use at your own risk.
#
# installs arch linux using the following:
# - disks:
#   - GPT
#   - filesystem: btrfs or lvm or zfs depending on $SETUP_SCHEME
#   - dm-crypt: LUKS on a partition (if btrfs or lvm in $SETUP_SCHEME)
#   - efi: /efi + /boot using bind mount
#########################################################################################

set -e
set -x

SETUP_DEVICE=/dev/nvme0n1 # /dev/sda or /dev/vda
SETUP_SCHEME=btrfs-on-luks # allowed values: lvm-on-luks, btrfs-on-luks, zfs
SETUP_ENCRYPTION_PASSWORD="SecretPassword!"

# validate params
if [[ ! "$SETUP_SCHEME" =~ ^(lvm-on-luks|btrfs-on-luks|zfs)$ ]]; then
    echo "invalid SETUP_SCHEME: $SETUP_SCHEME"
    exit 1
fi
if [ ! -b $SETUP_DEVICE ]; then
    echo "device doesn't exist: $SETUP_DEVICE"
    exit 1
fi

if [ "$SETUP_SCHEME" = "zfs" ]; then
    if ! modprobe zfs; then
        echo "ZFS module not loaded. Attempting to install it"
        curl -s https://eoli3n.github.io/archzfs/init | bash

        if ! modprobe zfs; then
            echo "ZFS module not loaded. Use build_zfs_archiso.sh to make an archiso with zfs modules. Aborting..."
            exit 1
        fi
    fi
fi

# update the system clock
timedatectl set-ntp true

# partition the disks
parted $SETUP_DEVICE mklabel gpt
parted $SETUP_DEVICE --align optimal \
       mkpart ESP fat32 1MiB 1000MiB \
       set 1 esp on \
       mkpart root 1000MiB 100%
sleep 1

if [[ "$SETUP_SCHEME" =~ ^(lvm-on-luks|btrfs-on-luks)$ ]]; then
    # encrypt partition
    # https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system
    echo "encrypting disk: /dev/disk/by-partlabel/root"
    echo -n "$SETUP_ENCRYPTION_PASSWORD" | cryptsetup -y -v luksFormat --type luks2 /dev/disk/by-partlabel/root -
    echo -n "$SETUP_ENCRYPTION_PASSWORD" | cryptsetup open /dev/disk/by-partlabel/root cryptroot -
fi

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
    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@opt
    btrfs subvolume create /mnt/@pkg
    btrfs subvolume create /mnt/@snapshots

    # mount the subvolumes
    umount /mnt
    mount_opts=noatime,compress=zstd,x-mount.mkdir
    mount -o $mount_opts,subvol=@          /dev/mapper/cryptroot /mnt
    mount -o $mount_opts,subvol=@home      /dev/mapper/cryptroot /mnt/home
    mount -o $mount_opts,subvol=@log       /dev/mapper/cryptroot /mnt/var/log
    mount -o $mount_opts,subvol=@opt       /dev/mapper/cryptroot /mnt/opt
    mount -o $mount_opts,subvol=@pkg       /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
    mount -o $mount_opts,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
    mount -o $mount_opts,subvol=/          /dev/mapper/cryptroot /mnt/btrfs

    chattr +C /mnt/var/log # disable CoW on @log
elif [ "$SETUP_SCHEME" = "zfs" ]; then
    # create the zpool
    # NOTE: we can enable autotrim=on. but maybe just enable systemd timer for trimming?
    echo -n "$SETUP_ENCRYPTION_PASSWORD" | \
        zpool create -f -o ashift=12    \
              -O acltype=posixacl       \
              -O relatime=on            \
              -O xattr=sa               \
              -O dnodesize=auto         \
              -O normalization=formD    \
              -O mountpoint=none        \
              -O canmount=off           \
              -O devices=off            \
              -O compression=zstd       \
              -O encryption=aes-256-gcm \
              -O keyformat=passphrase   \
              -O keylocation=prompt     \
              -R /mnt                   \
              zroot /dev/disk/by-partlabel/root

    # create the datasets
    # TODO: should we create similar datasets as btrfs such as log and pacman_pkgs?
    zfs create -o mountpoint=none zroot/data
    zfs create -o mountpoint=none zroot/ROOT
    zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/default
    zfs create -o mountpoint=/home zroot/data/home
    zfs umount -a
    rmdir /mnt/home

    # export and import to validate our configuration
    zpool export zroot
    zpool import -d /dev/disk/by-partlabel/ -R /mnt zroot -N
    echo -n "$SETUP_ENCRYPTION_PASSWORD" | zfs load-key zroot

    # configure the root system
    zpool set bootfs=zroot/ROOT/default zroot
    zpool set cachefile=/etc/zfs/zpool.cache zroot
    zfs mount zroot/ROOT/default # manually mount this since it uses canmount=noauto
    zfs mount -a
    mkdir -p /mnt/etc/zfs/
    mv /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
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
         diffutils \
         fakeroot \
         git \
         iptables-nft \
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
elif [ "$SETUP_SCHEME" = "zfs" ]; then
    sed -i '/^zroot/,+1d' /mnt/etc/fstab # remove zfs entries from fstab
fi

# configure arch in chroot
cp arch_install_chroot.sh /mnt/root/
arch-chroot /mnt /root/arch_install_chroot.sh --scheme $SETUP_SCHEME
rm /mnt/root/arch_install_chroot.sh

read -r -p "Press [Enter] to reboot: "

# systemd-resolved: make /etc/resolv.conf point to the systemd DNS stub file
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

# exit
umount -R /mnt
if [ "$SETUP_SCHEME" = "lvm-on-luks" ]; then
    lvchange --activate n vg0
    cryptsetup close cryptroot
elif [ "$SETUP_SCHEME" = "btrfs-on-luks" ]; then
    cryptsetup close cryptroot
elif [ "$SETUP_SCHEME" = "zfs" ]; then
    zfs umount -a
    zpool export zroot
fi
systemctl reboot
