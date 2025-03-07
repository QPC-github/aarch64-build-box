#!/bin/sh

set -eux
set -o pipefail

if ! test -b /dev/nvme0n1p1; then
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/nvme0n1
      o # clear the in memory partition table
      n # new partition
      p # primary partition
      1 # partition number 1
        # default - start at beginning of disk
      +100M  # default, extend partition to end of disk
      n # new partition
      p # primary partition
      2 # partition number 2
        # default start
        # default end
      p # print the in-memory partition table
      w # write the partition table
      q # and we're done
EOF
fi

if ! test -L /dev/disk/by-label/persist; then
    mkfs.ext4 -L persist /dev/nvme0n1p1
fi

zpool \
    create -f \
    -O sync=disabled \
    -O mountpoint=none \
    -O atime=off \
    -O compression=lz4 \
    -O xattr=sa \
    -O acltype=posixacl \
    -O relatime=on \
    -o ashift=12 \
    rpool \
    /dev/nvme0n1p2

zfs create -o mountpoint=legacy rpool/root
