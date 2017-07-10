#!/bin/bash

# Initializing variables
language="en_US"
keyboardLayout="us"
isUEFImode=false
isConnectedToInternet=false
declare -a additionalLanguages

tmp1="en_US"


# Check internet connection
if ping -c 1 archlinux.org &> /dev/null; then
	isConnectedToInternet=true
else
	isConnectedToInternet=false
	echo $'Your internet connection does not work. You cannot install ArchLinux offline.\nTry using a wired connection.\n'
	read -n 1 -s -r -p ":: Press any key to reboot"
	reboot
fi

# Check boot mode
if [ -d "/sys/firmware/efi/efivars/" ]; then
	isUEFImode=true
else
	isUEFImode=false
fi

# Update system clock
timedatectl set-ntp true

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
	echo "Introduce one language at time and then press ENTER. Introduce \"done\" (without quotes) to finish."
	while [ $tmp1 != "done" ]; do
		read -p "# " tmp1
		if [ $tmp1 != "done" -a $tmp1 != "en_US" ]; then
			additionalLanguages+=($tmp1)
		fi
	done
	#echo ${additionalLanguages[x]}
fi
