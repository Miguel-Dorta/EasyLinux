#!/bin/zsh

# Initializing variables
language="en_US"
keyboardLayout="us"
timeZone="/usr/share/zoneinfo/Etc/UTC"
isUEFImode=false
isConnectedToInternet=false
declare -a additionalLanguages
declare -i counter=0


# Previous checking of internet connection
if ping -c 1 archlinux.org &> /dev/null; then
	isConnectedToInternet=true
else
	isConnectedToInternet=false
	echo $'Your internet connection does not work. You cannot install ArchLinux offline.\nTry using a wired connection.\n'
	read -n 1 -s -r -p ":: Press any key to reboot"
	reboot
fi


### User inputs ###
# Set keyboard layout
read -p "Define your keyboard layout (default \"us\"): " keyboardLayout
loadkeys $keyboardLayout

# Set main language
read -p "Define your main language (default \"en_US\"): " language
if [ $language != "en_US" ]; then
	additionalLanguages+=('en_US')
fi

# Set other languages
read -p "Do you want to add any additional language? [y/n]: " yn1
while [ $yn1 != "y" -a $yn1 != "n" ]; do
	read -p "Please, write \"y\" or \"n\" (without quotes): " yn1
done
if [ $yn1 == "y" ]; then
	tmp1="en_US"
	echo "Introduce one language at time and then press ENTER. Introduce \"done\" (without quotes) to finish."
	while [ $tmp1 != "done" ]; do
		read -p "# " tmp1
		if [ $tmp1 != "done" -a $tmp1 != "en_US" ]; then
			additionalLanguages+=($tmp1)
		fi
	done
	#echo ${additionalLanguages[x]}
fi

# Set time zone
echo " "
(cd /usr/share/zoneinfo && ls -d */)
read -p "Choose your region from the list above: " region
if [ $region = "America" ]; then
	(cd /usr/share/zoneinfo/America && ls -d */)
	read -p "Is your region one of those above? If it's yes, introduce it. If it's not, press ENTER: " subregion
	if [[ $subregion ]]; then
		region=$region'/'$subregion
	fi
fi
ls /usr/share/zoneinfo/$region
read -p "Introduce your city from the list above: " city
timeZone="/usr/share/zoneinfo/$region/$city"


### Installing process ###
# Check boot mode
if [ -d "/sys/firmware/efi/efivars/" ]; then
	isUEFImode=true
else
	isUEFImode=false
fi

# Update system clock
timedatectl set-ntp true


###########################################
# Partitioning and formatting script here #
###########################################
#
### UEFI clean disk installation
# # Make partition table
# parted <disk> mklabel gpt
#
# # Make EFI partition
# parted <disk> mkpart ESP fat32 1MiB 513MiB
# parted <disk> set 1 boot on
# mkfs.fat -F32 <disk/partition1>
# 
# # Make system partition
# parted <disk> mkpart primary xfs 513MiB 100%
# mkfs.xfs <disk/partition2>
# 
# # Mount partitions
# mount <disk/partition2> /mnt
# mkdir /mnt/boot
# mount <disk/partition1> /mnt/boot
# 
###########################################
# Partitioning and formatting script here #
###########################################


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
while [[ ${additionalLanguages[$counter]} ]]; do
	echo "${additionalLanguages[$counter]}.UTF-8 UTF-8" >> /mnt/etc/locale.gen
	counter+=1
done

# Operating now into the new system
arch-chroot /mnt << EOF
	ln -sf $timeZone /etc/localtime
	hwclock --systohc
	locale-gen
EOF
