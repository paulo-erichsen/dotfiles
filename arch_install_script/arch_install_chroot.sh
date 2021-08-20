#!/usr/bin/bash

#########################################################################################
# arch_install_chroot.sh
#
# https://wiki.archlinux.org/index.php/installation_guide#Configure_the_system
#
# please follow the arch linux installation guide for how to configure the stystem.
# this script is my own way to install but be warned that it WILL become outdated
#
# configures the following:
# - initramfs: dracut or mkinitcpio
# - kernel: linux
# - boot loader: systemd-boot
# - networking: systemd-resolved + systemd-networkd
# - swap file: systemd-swap (note: not affiliated with systemd project)
# - desktop environment: gnome
# - user: adds an aur and a local user
# - aur helper: paru
#########################################################################################

set -e
set -x

# TODO: bounce out of this script if it wasn't called by arch_install.sh

SETUP_TIMEZONE=America/Denver
SETUP_HOSTNAME=arch-pc
SETUP_USER=paulo
SETUP_AUR_USER=aur_builder
SETUP_USER_PASSWORD=default
SETUP_ROOT_PASSWORD=default
SETUP_INITRAMFS_DRACUT=true # if this is not "true", then mkinitcpio is assumed
SETUP_SCHEME=btrfs-on-luks

### read command line params
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--scheme) SETUP_SCHEME="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

### users
useradd --create-home --shell /bin/bash $SETUP_USER
useradd --create-home --shell /bin/bash -g wheel $SETUP_AUR_USER
# change passwords
echo "$SETUP_USER:$SETUP_USER_PASSWORD" | chpasswd
echo "root:$SETUP_ROOT_PASSWORD" | chpasswd
# add users to sudoers
AUR_SUDOERS_FILE=/etc/sudoers.d/$SETUP_AUR_USER-allow-to-sudo-pacman
sed -i "/^root ALL=(ALL) ALL/a $SETUP_USER ALL=(ALL) ALL" /etc/sudoers
echo 'aur_builder ALL=(ALL) NOPASSWD: /usr/bin/pacman' > $AUR_SUDOERS_FILE
chmod 0440 $AUR_SUDOERS_FILE
# check the sudoers files since we didn't edit with visudo
visudo --check
visudo --check --file $AUR_SUDOERS_FILE

### aur helper: paru
sudo -u $SETUP_AUR_USER bash <<EOF
git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
cd /tmp/paru-bin
makepkg -sri --needed --noconfirm
EOF

### timezone, locale, hostname
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

### initramfs
if [ "$SETUP_INITRAMFS_DRACUT" = true ]; then
    sudo -u $SETUP_AUR_USER paru -S --noconfirm dracut dracut-hook
else
    pacman -S --noconfirm mkinitcpio
    if [ "$SETUP_SCHEME" = "lvm-on-luks" ]; then
        sed -i 's/^\(HOOKS=\).*$/\1(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
    elif [ "$SETUP_SCHEME" = "btrfs-on-luks" ]; then
        sed -i 's/^\(HOOKS=\).*$/\1(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt btrfs filesystems fsck)/' /etc/mkinitcpio.conf
        # NOTE: maybe add BINARIES=(/usr/bin/btrfs)
    fi
fi

# install linux
pacman -S --noconfirm linux

### boot loader: systemd-boot
bootctl --esp-path /efi install
# install microcode
if lscpu | grep -q GenuineIntel; then
    SETUP_CPU_UCODE=intel-ucode
elif lscpu | grep -q AuthenticAMD; then
    SETUP_CPU_UCODE=amd-ucode
fi
if [[ -v SETUP_CPU_UCODE ]]; then
    pacman -S --noconfirm $SETUP_CPU_UCODE
fi

# configure systemd-boot
cat > /efi/loader/loader.conf <<EOF
# timeout 4
default arch
EOF

SETUP_DISK_UUID=$(blkid -s UUID -o value /dev/disk/by-partlabel/root)
if [ "$SETUP_SCHEME" = "lvm-on-luks" ]; then
    KERNEL_PARAMETERS="rd.luks.name=$SETUP_DISK_UUID=cryptroot root=/dev/vg0/root rw"
elif [ "$SETUP_SCHEME" = "btrfs-on-luks" ]; then
    KERNEL_PARAMETERS="rd.luks.name=$SETUP_DISK_UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw"
fi
cat > /efi/loader/entries/arch.conf <<EOF
title  arch linux
linux  /arch/vmlinuz-linux
initrd /arch/$SETUP_CPU_UCODE.img
initrd /arch/initramfs-linux.img
options $KERNEL_PARAMETERS
EOF

cat > /efi/loader/entries/arch-fallback.conf <<EOF
title  arch linux (fallback)
linux  /arch/vmlinuz-linux
initrd /arch/$SETUP_CPU_UCODE.img
initrd /arch/initramfs-linux-fallback.img
options $KERNEL_PARAMETERS
EOF

sudo -u $SETUP_AUR_USER paru -S --noconfirm systemd-boot-pacman-hook

### network configuration: systemd-resolved + systemd-networkd (dhcp)
cat > /etc/systemd/network/20-wired.network <<EOF
[Match]
Name=en*

[Network]
DHCP=ipv4
EOF
systemctl enable systemd-resolved.service
systemctl enable systemd-networkd.service

# systemd-swap
pacman -S --noconfirm systemd-swap
sed -i 's/swapfc_enabled=0/swapfc_enabled=1/' /etc/systemd/swap.conf
sed -i 's/swapfc_force_preallocated=0/swapfc_force_preallocated=1/' /etc/systemd/swap.conf
systemctl enable systemd-swap.service

# systemd-oomd
systemctl enable systemd-oomd.service

# snapper - btrfs snapshots
if [ "$SETUP_SCHEME" = "btrfs-on-luks" ]; then
    # TODO: setup snapper with a "live" folder for snapshots
    # - https://www.reddit.com/r/archlinux/comments/fkcamq/noob_btrfs_subvolume_layout_help/fkt6wqs/?context=3
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots
    mkdir /.snapshots
    mount /.snapshots
    chmod 750 /.snapshots
    systemctl enable snapper-timeline.timer
    systemctl enable snapper-cleanup.timer
fi

### user specific config
# install reflector first to allow fast package updates and downloads
pacman -S --noconfirm reflector
reflector \
    --verbose \
    --latest 64 \
    --number 16 \
    --age 24 \
    --protocol https \
    --country 'United States' \
    --sort rate \
    --save /etc/pacman.d/mirrorlist

# upgrade the system
pacman -Syu --noconfirm

# TODO: detect gpu amd/nvidia/intel and install appropriate drivers
# amd: xf86-video-amdgpu
# nvidia: nvidia
# intel: xf86-video-intel

# sound: pipewire-pulse
# NOTE: install pipewire first such that when we install the desktop environment below, it won't try to install pulseaudio
pacman -S --noconfirm --needed \
       pipewire \
       pipewire-alsa \
       pipewire-pulse \
       gst-plugin-pipewire

# desktop environment: gnome (minimal) + utilities
pacman -S --noconfirm --needed \
       eog \
       evince \
       file-roller \
       gdm \
       gedit \
       gnome-calculator \
       gnome-clocks \
       gnome-control-center \
       gnome-desktop \
       gnome-screenshot \
       gnome-system-monitor \
       gnome-terminal \
       pavucontrol \
       nautilus \
       simple-scan
systemctl enable gdm.service # gnome display manager

# lock the root password and expire the user's password
echo 'locking the root account'
passwd --lock root
echo "expiring the password for user: $SETUP_USER"
passwd --expire $SETUP_USER # expiring allows the user to reset their password when they login
# for some reason I wasn't able to change the expired password from the terminal without this line
echo "password  include   system-local-login" >> /etc/pam.d/login
