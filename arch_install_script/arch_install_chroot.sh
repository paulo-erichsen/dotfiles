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
# - zram
# - desktop environment: gnome
# - user: adds an aur and a local user
# - aur helper: paru
#########################################################################################

set -e
set -x

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

if [ "$SETUP_SCHEME" = "zfs" ] && [ "$SETUP_INITRAMFS_DRACUT" != "true" ]; then
    echo "Operation not supported! zfs + mkinitcpio + systemd-boot has not been implemented here. Use dracut instead"
    exit 1
fi

### users
useradd --create-home --shell /bin/bash $SETUP_USER
useradd --create-home --shell /bin/bash -g wheel $SETUP_AUR_USER
# change passwords
echo "$SETUP_USER:$SETUP_USER_PASSWORD" | chpasswd
echo "root:$SETUP_ROOT_PASSWORD" | chpasswd
# add users to sudoers
AUR_SUDOERS_FILE=/etc/sudoers.d/$SETUP_AUR_USER-allow-to-sudo-pacman
sed -i "/^root ALL=(ALL:ALL) ALL/a $SETUP_USER ALL=(ALL:ALL) ALL" /etc/sudoers
echo 'aur_builder ALL=(ALL:ALL) NOPASSWD: /usr/bin/pacman' > $AUR_SUDOERS_FILE
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
    elif [ "$SETUP_SCHEME" = "zfs" ]; then
        echo "OPERATION NOT SUPPORTED (native zfs encryption + mkinitcpio + systemd-boot)"
        exit 1
    fi
fi

# install the kernel
if [ "$SETUP_SCHEME" != zfs ]; then
    pacman -S --noconfirm linux
else
    # add [archzfs] repo before [core]
    sed -i "/^\[core\]/i \[archzfs\]\nServer = http:\/\/archzfs.com/\$repo\/x86_64\n" /etc/pacman.conf
    # import and sign the repo key
    ARCHZFS_REPO_KEY=$(curl --fail --silent --location https://git.io/JsfVS)
    pacman-key --recv-keys "$ARCHZFS_REPO_KEY"
    pacman-key --lsign-key "$ARCHZFS_REPO_KEY"
    pacman -Sy
    # try to install zfs-linux. if that fails, fallback to dkms
    if ! pacman -S --noconfirm zfs-linux; then
        pacman -S --noconfirm linux linux-headers zfs-dkms
    fi
    systemctl enable \
              zfs.target \
              zfs-import-cache.service \
              zfs-mount.service \
              zfs-import.target
fi

# install linux-firmware and mesa
pacman -S --noconfirm --needed linux-firmware mesa

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
    KERNEL_PARAMETERS="zswap.enabled=0 rd.luks.options=discard rd.luks.name=$SETUP_DISK_UUID=cryptroot root=/dev/vg0/root rw"
elif [ "$SETUP_SCHEME" = "btrfs-on-luks" ]; then
    KERNEL_PARAMETERS="zswap.enabled=0 rd.luks.options=discard rd.luks.name=$SETUP_DISK_UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw"
elif [ "$SETUP_SCHEME" = "zfs" ]; then
    KERNEL_PARAMETERS="zswap.enabled=0 root=zfs:zroot/ROOT/default rw"
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

systemctl enable systemd-boot-update.service

### network configuration: systemd-resolved + systemd-networkd (dhcp)
cat > /etc/systemd/network/20-wired.network <<EOF
[Match]
Name=en*

[Network]
DHCP=ipv4
EOF

cat > /etc/systemd/network/25-wireless.network <<EOF
[Match]
Name=wl*

[Network]
DHCP=ipv4
IgnoreCarrierLoss=3s
EOF

# wifi
if ip -oneline link show | grep -q wlan; then
    pacman -S --noconfirm iwd
    systemctl enable iwd.service
fi

systemctl enable \
          systemd-resolved.service \
          systemd-networkd.service

# gpu
# TODO: check nvidia gpu present and if so, install the nvidia package

# enable SSD TRIM
if [ "$SETUP_SCHEME" != "btrfs-on-luks" ]; then
    # not enabling this on btrfs since it will use discard=async automatically on linux 6.2 and newer
    systemctl enable fstrim.timer
fi

# systemd-oomd
systemctl enable systemd-oomd.service

# zram
pacman -S --noconfirm zram-generator
cat > /etc/systemd/zram-generator.conf <<EOF
# This section describes the settings for /dev/zram0
[zram0]
zram-size = min(ram / 2, 4096)
EOF

# snapper - btrfs snapshots
if [ "$SETUP_SCHEME" = "btrfs-on-luks" ]; then
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots
    mkdir /.snapshots
    mount /.snapshots
    chmod 750 /.snapshots
    systemctl enable \
              snapper-boot.timer \
              snapper-timeline.timer \
              snapper-cleanup.timer

    # install a utility to rollback since "snapper rollback" won't work
    # https://wiki.archlinux.org/title/snapper#Restoring_/_to_its_previous_snapshot
    sudo -u $SETUP_AUR_USER paru -S --noconfirm snapper-rollback
    sed -i 's/^\(mountpoint = \).*$/\1\/btrfs/' /etc/snapper-rollback.conf
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

# sound: pipewire-pulse
# NOTE: install pipewire first such that when we install the desktop environment below, it won't try to install pulseaudio
pacman -S --noconfirm --needed \
       pipewire \
       pipewire-alsa \
       pipewire-jack \
       pipewire-pulse \
       gst-plugin-pipewire

# desktop environment: gnome (minimal) + basic utilities
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
       gnome-keyring \
       gnome-screenshot \
       gnome-system-monitor \
       gnome-terminal \
       pavucontrol \
       nautilus \
       simple-scan \
       xdg-desktop-portal-gnome
systemctl enable gdm.service # gnome display manager

# lock the root password and expire the user's password
echo 'locking the root account'
passwd --lock root
echo "expiring the password for user: $SETUP_USER"
passwd --expire $SETUP_USER # expiring allows the user to reset their password when they login
