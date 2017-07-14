#!/bin/bash

# Initializing variables
language="en_US"
keyboardLayout="us"
timeZone="/usr/share/zoneinfo/Etc/UTC"
localHostname="arch"
installationDisk="/dev/sda"
otherDisk="/dev/sdb"
isUEFImode=false
isConnectedToInternet=false
yn1="n"
yn2="n"
declare -a additionalLanguages
declare -i installationMode=0
declare -i installationOption=0
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
fi

# Set time zone
echo " "
(cd /usr/share/zoneinfo && ls -d */)
read -p "Choose your region from the list above: " region
if [ $region = "America" ]; then
	echo " "
	(cd /usr/share/zoneinfo/America && ls -d */)
	read -p "Is your region one of those above? If it's yes, introduce it. If it's not, press ENTER: " subregion
	if [[ $subregion ]]; then
		region+="/$subregion"
	fi
fi
echo " "
ls /usr/share/zoneinfo/$region
read -p "Introduce your city from the list above: " city
timeZone="/usr/share/zoneinfo/$region/$city"

# Set hostname
read -p "Define system's hostname: " localHostname

# Set installation mode
echo $'\n1/Clean    2/Dual boot (Windows)    3/Dual boot (Mac)'
read -p "Choose one of the installation methods from the list above: " installationMode
while [ $installationMode < 1 -o $installationMode > 3 ]; do
	read -p "Please, write the number of the installation methods above: " installationMode
done
if [ $installationMode != 1 ]; then
	echo $'\n1/Both OS in the same disk    2/Each OS in a different disk'
	read -p "Choose one of the options: " installationOption
	while [ $installationOption < 1 -o $installationOption > 2 ]; do
		read -p "Please, write the number of the options above: " installationOption
	done
fi
if [ $installationOption = 2 ]; then
	read -p "Do you want to use a boot manager in common? [y/n]: " yn2
	while [ $yn2 != "y" -a $yn2 != "n" ]; do
		read -p "Please, write \"y\" or \"n\" (without quotes): " yn2
	done
fi
echo " "
parted -l
read -p "Select the disk you want to install ArchLinux: " installationDisk
if [ $yn2 = "y" ]; then
	read -p "Select the disk where the other OS is installed: " otherDisk
fi
part1="${installationDisk}1"
part2="${installationDisk}2"


### Installing process ###
# Check boot mode
if [ -d "/sys/firmware/efi/efivars/" ]; then
	isUEFImode=true
else
	isUEFImode=false
fi

# Update system clock
timedatectl set-ntp true

# Partitioning and formatting
if [ $installationMode = 1 ]; then
	if [ $isUEFImode = true ]; then
		# Make partition table
		parted $installationDisk mklabel gpt

		# Make EFI partition
		parted $installationDisk mkpart ESP fat32 1MiB 513MiB
		parted $installationDisk set 1 boot on
		mkfs.fat -F32 $part1
	else
		# Make partition table
		parted $installationDisk mklabel msdos
		
		# Make boot partition
		parted $installationDisk mkpart primary ext4 1MiB 513MiB
		parted $installationDisk set 1 boot on
		mkfs.ext4 $part1
		tune2fs -O ^has_journal $part1
	fi
	# Make system partition
	parted $installationDisk mkpart primary xfs 513MiB 100%
	mkfs.xfs $part2

	# Mount partitions
	mount $part2 /mnt
	mkdir /mnt/boot
	mount $part1 /mnt/boot
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
while [[ ${additionalLanguages[$counter]} ]]; do
	echo "${additionalLanguages[$counter]}.UTF-8 UTF-8" >> /mnt/etc/locale.gen
	counter+=1
done

# Operating now into the new system
arch-chroot /mnt << EOF
	ln -sf $timeZone /etc/localtime
	hwclock --systohc

	locale-gen
	echo "LANG=$language.UTF-8" > /etc/locale.conf
	echo "KEYMAP=$keyboardLayout" > /etc/vconsole.conf

	echo $localHostname > /etc/hostname
	sed -i "8i 127.0.1.1 $localHostname.localdomain $localHostname" /etc/hosts

	pacman -S networkmanager --noconfirm

	systemctl disable dhcpcd.service
	systemctl disable dhcpcd@enp0s3.service
	systemctl enable NetworkManager

	exit
EOF

# Installing boot manager
if [ isUEFImode = "true" ]; then
	arch-chroot /mnt << EOF
		pacman -S refind-efi --noconfirm

		refind-install --usedefault $part1

		exit
	EOF

	if [ -e "/mnt/boot/refind_linux.conf" ]; then
		echo "rEFInd installed"
	else
		sysPartUUID=$(blkid -o value -s UUID ${part2})
		echo "\"Boot with standard options\" \"rw root=UUID=$sysPartUUID rootfstype=xfs add_efi_memmap\"" > /mnt/boot/refind_linux.conf
		echo "\"Boot to single-user mode\"    \"rw root=UUID=$sysPartUUID rootfstype=xfs add_efi_memmap single\"" >> /mnt/boot/refind_linux.conf
		echo "\"Boot with minimal options\"   \"ro root=UUID=$sysPartUUID\"" >> /mnt/boot/refind_linux.conf
	fi
fi
if [ isUEFImode = "false" ]; then
	arch-chroot /mnt << EOF
		pacman -S grub --noconfirm
		
		grub-install --target=i386-pc $part1 # Command not found
		grub-mkconfig -o /boot/grub/grub.cfg # Command not found

		exit
	EOF
fi

# Umount partitions & reboot
umount -R /mnt
reboot
