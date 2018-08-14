#!/usr/bin/env bash

/usr/bin/rsync -av --progress --delete /mnt/data/my_files/ nas:/share/my_files/
/usr/bin/rsync -av --progress --delete /mnt/data/music/    nas:/share/Multimedia/music/
