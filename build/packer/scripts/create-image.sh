#!/bin/bash
# Script taken from: Ivan Velichko's Docker-to-Linux GitHub Repository
# Source File: https://github.com/iximiuz/docker-to-linux/blob/master/create_image.sh
# License: UNLICENSED

set -e

echo_blue() {
  local font_blue="\033[94m"
  local font_bold="\033[1m"
  local font_end="\033[0m"

  echo -e "\n${font_blue}${font_bold}${1}${font_end}"
}

echo_blue "[Install APT dependencies]"
DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y extlinux fdisk qemu-utils

echo_blue "[Create disk image]"
dd if=/dev/zero of=/artifacts/${DISTR}.img bs=$(expr 1024 \* 1024 \* 1024) count=1

echo_blue "[Make partition]"
sfdisk /artifacts/${DISTR}.img </os/config/partition.txt

echo_blue "\n[Format partition with ext4]"
losetup -D
LOOPDEVICE=$(losetup -f)
echo -e "\n[Using ${LOOPDEVICE} loop device]"
losetup -o $(expr 512 \* 2048) ${LOOPDEVICE} /artifacts/${DISTR}.img
mkfs.ext4 ${LOOPDEVICE}

echo_blue "[Copy ${DISTR} directory structure to partition]"
mkdir -p /output/mnt
mount -t auto ${LOOPDEVICE} /output/mnt/
cp -dR /artifacts/${DISTR}.dir/. /output/mnt/

echo_blue "[Setup extlinux]"
extlinux --install /output/mnt/boot/
cp /os/config/${DISTR}/syslinux.cfg /output/mnt/boot/syslinux.cfg

echo_blue "[Unmount]"
umount /output/mnt
losetup -D

echo_blue "[Write syslinux MBR]"
dd if=/usr/lib/syslinux/mbr/mbr.bin of=/artifacts/${DISTR}.img bs=440 count=1 conv=notrunc

echo_blue "[Convert]"
qemu-img convert -c /artifacts/${DISTR}.img -O qcow2 /artifacts/${DISTR}.qcow2
qemu-img convert /artifacts/${DISTR}.img -O vmdk /artifacts/${DISTR}.vmdk
qemu-img convert /artifacts/${DISTR}.img -O vhdx -o subformat=dynamic /artifacts/${DISTR}.vhdx
