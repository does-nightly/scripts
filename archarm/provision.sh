#!/bin/sh

display_usage() { 
  echo "Usage: archarm [OPTION]... [DISK]..."
  echo -e "\n   -m, --mirror Manually specify a mirror to use, rather than the default http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.g"
  exit 1
}

if [[ $USER != "root" ]]; then 
  echo "This script must be run as root!" 
  exit 1
fi 

MIRROR=http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz
TEMP_BOOT_DIR=$(mktemp -dp /mnt/)
TEMP_ROOT_DIR=$(mktemp -dp /mnt/)

while [ "$2" != "" ]; do
    PARAM=`echo $2 | awk -F= '{print $2}'`
    VALUE=`echo $2 | awk -F= '{print $3}'`
    case $PARAM in
        -h | --help)
            display_usage
            exit
            ;;
        -m|--mirror)
            MIRROR=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            display_usage
            exit 1
            ;;
    esac
    shift
done

DISK=$1

if [ -b "$DISK" ]
then
	echo -e "\e[32m[ Unmounting "${DISK}p1" ]"
	umount "${DISK}p1"
	echo -e "\e[32m[ Unmounting "${DISK}p2" ]"
	umount "${DISK}p2"
	echo -e "\e[32m[ Using fdisk to format and partition the supplied disk ]"
	echo -e o\\nn\\n\\n\\n\\n+100M\\nt\\nc\\nn\\n\\n\\n\\n\\nw\\n | fdisk -W always $DISK
	echo -e "\e[32m[ Running partprobe, since the previous command is too fast for its own good ]"
	partprobe
	echo -e "\e[32m[ making fat32 filesystem on "${DISK}p1" ]"
	mkfs.vfat "${DISK}p1"
	echo -e "\e[32m[ making ext4 filesystem on "${DISK}p2" ]"
	mkfs.ext4 "${DISK}p2"
	echo -e "\e[32m[ creating /tmp/archpiboot /tmp/archpiroot ]"
	echo -e "\e[32m[ mounting /tmp/archpiboot /tmp/archpiroot ]"
	mount "${DISK}p1" $TEMP_BOOT_DIR
	mount "${DISK}p2" $TEMP_ROOT_DIR
	echo -e "\e[32m[ wgetting your arch media from\n $MIRROR ]"
 	wget -qO- $MIRROR |  tar xvzp -C $TEMP_ROOT_DIR 
	sync
	echo -e "\e[32m[ Moving files to disks ]"
	mv $TEMP_ROOT_DIR/boot/* $TEMP_BOOT_DIR
	umount $TEMP_ROOT_DIR $TEMP_BOOT_DIR
	rm -rf $TEMP_ROOT_DIR $TEMP_BOOT_DIR

else
	echo ""$DISK" does not exist, or is not a block device, you must specify a disk such as /dev/mmcblk0"
fi
