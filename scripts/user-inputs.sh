#!/bin/bash

# Initializing variables
language="en_US"
keyboardLayout="us"
timeZone="/usr/share/zoneinfo/Etc/UTC"
localHostname="arch"
installationDisk="/dev/sda"
bootPart="/dev/sda1"
rootPart="/dev/sda2"
installationMode="0"
isUEFImode=false
yn1="null"
declare -a additionalLanguages

# Change working directory
cd /

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
	addLang="en_US"
	echo "Introduce one language at time and then press ENTER. Introduce \"done\" (without quotes) to finish."
	while [ $addLang != "done" ]; do
		read -p "# " addLang
		if [ $addLang != "done" -a $addLang != "en_US" ]; then
			additionalLanguages+=($addLang)
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
echo $'\n1/Clean    2/Advanced'
read -p "Choose one of the installation methods from the list above: " installationMode
while [ $installationMode != 1 -a $installationMode != 2 ]; do
	read -p "Please, write \"1\" or \"2\" (without quotes): " installationMode
done

echo " "
if [ $installationMode = "1" ]; then
	# Set disk to clean
	parted $installationDisk print devices
	read -p "Select the disk you want to install ArchLinux (press ENTER for more info): " installationDisk
	if [ -z $installationDisk ]; then
		parted -l
		read -p "Select the disk you want to install ArchLinux: " installationDisk
	fi
else
	# Set partitions (advanced mode)
	fdisk -l
	read -p "Introduce the root (/) partition: " rootPart
	read -p "Introduce the boot (/boot) partition: " bootPart
	read -p "Introduce the home (/home) partition (ENTER to skip): " homePart
	read -p "Introduce the SWAP partition (ENTER to skip): " swapPart
fi


### Write config file ###
echo -e "# EasyLinux config file
keyboardLayout=$keyboardLayout
language=$language
timeZone=$timeZone
localHostname=$localHostname
installationMode=$installationMode
installationDisk=$installationDisk
rootPart=$rootPart
bootPart=$bootPart" > /EasyLinux/easylinux.config
# Add additionals partitions if they exist
if [[ $homePart ]]; then
	echo "homePart=$homePart" >> /EasyLinux/easylinux.config
fi
if [[ $swapPart ]]; then
	echo "swapPart=$swapPart" >> /EasyLinux/easylinux.config
fi
# Add boot type
if [ -d "/sys/firmware/efi/efivars/" ]; then
	isUEFImode=true
else
	isUEFImode=false
fi
echo "isUEFImode=$isUEFImode" >> /EasyLinux/easylinux.config
# Add language code
echo "declare -a additionalLanguages" >> /EasyLinux/easylinux.config
for otherLang in ${additionalLanguages[@]}; do
	echo "additionalLanguages+=($otherLang)" >> /EasyLinux/easylinux.config
done
