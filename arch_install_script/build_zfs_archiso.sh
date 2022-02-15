#!/usr/bin/bash

set -e
set -x

# https://wiki.archlinux.org/title/Unofficial_user_repositories#archzfs
ARCHZFS_REPO_KEY=$(curl --fail --silent --location https://git.io/JsfVS)
ARCHISO_BASE_PATH=/tmp/archlive-zfs
ARCHISO_PROFILE_PATH=$ARCHISO_BASE_PATH/profile
ARCHISO_WORK_PATH=$ARCHISO_BASE_PATH/work
ARCHISO_OUT_PATH=$ARCHISO_BASE_PATH/out

pacman -Q archiso 2>/dev/null || sudo pacman -S --noconfirm --needed archiso
sudo rm -rf $ARCHISO_BASE_PATH
mkdir -p $ARCHISO_PROFILE_PATH
cp -r /usr/share/archiso/configs/releng/* $ARCHISO_PROFILE_PATH
# add [archzfs] repo before [core]
sed -i "/^\[core\]/i \[archzfs\]\nServer = http:\/\/archzfs.com/\$repo\/x86_64\n" $ARCHISO_PROFILE_PATH/pacman.conf
echo -e "linux-headers\nzfs-dkms" >> $ARCHISO_PROFILE_PATH/packages.x86_64
# import and sign the repo key
if ! pacman-key --list-keys 2>/dev/null | grep --quiet "$ARCHZFS_REPO_KEY"; then
    sudo pacman-key --recv-keys "$ARCHZFS_REPO_KEY" && sudo pacman-key --lsign-key "$ARCHZFS_REPO_KEY"
fi
sudo mkarchiso -v -w $ARCHISO_WORK_PATH -o $ARCHISO_OUT_PATH $ARCHISO_PROFILE_PATH
sudo rm -rf $ARCHISO_WORK_PATH
