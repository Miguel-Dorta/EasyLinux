#!/bin/bash

# Import variables
source /EasyLinux/easylinux.config

# Change working directory
cd /

# Update system clock
timedatectl set-ntp true

# Partitioning and formatting
if [ $partitionMode = "1" ]; then
	bootPart="${installationDisk}1"
	swapPart="${installationDisk}2"
	rootPart="${installationDisk}3"
	
	if [ $isUEFImode = true ]; then
		# Make partition table
		parted $installationDisk mklabel gpt

		# Make EFI partition
		parted $installationDisk mkpart ESP fat32 1MiB 513MiB
		parted $installationDisk set 1 boot on
		mkfs.fat -F32 $bootPart
	else
		# Make partition table
		parted $installationDisk mklabel msdos
		
		# Make boot partition
		parted $installationDisk mkpart primary ext4 1MiB 513MiB
		parted $installationDisk set 1 boot on
		mkfs.ext4 $bootPart
		tune2fs -O ^has_journal $bootPart
	fi
	# Make swap partition
	parted $installationDisk mkpart primary linux-swap 513MiB 2561MiB

	# Make system partition
	parted $installationDisk mkpart primary xfs 2561MiB 100%
	mkfs.xfs $rootPart -f
fi

# Mount partitions
mount $rootPart /mnt
mkdir /mnt/boot
mount $bootPart /mnt/boot
if [[ $homePart ]]; then
	mkdir /mnt/home
	mount $homePart /mnt/home
fi
if [[ $swapPart ]]; then
	mkswap $swapPart
	swapon $swapPart
fi

# Sorting mirrors by their speed
# THIS NEEDS TO BE CHANGED. RANKMIRRORS WILL BE UNAVAILABLE IN THE NEXT RELEASE OF PACMAN
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

# Install base packages
pacstrap /mnt base

# Generate fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Adding locations
echo "$language.UTF-8 UTF-8" >> /mnt/etc/locale.gen
for otherLang in ${additionalLanguages[@]}; do
	echo "$otherLang.UTF-8 UTF-8" >> /mnt/etc/locale.gen
done
