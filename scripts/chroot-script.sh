#!/bin/bash

# Import variables
source /EasyLinux/easylinux.config

# Configure time zone
ln -sf $timeZone /etc/localtime
hwclock --systohc

# Configure locations
locale-gen
echo "LANG=$language.UTF-8" > /etc/locale.conf
echo "KEYMAP=$keyboardLayout" > /etc/vconsole.conf

# Configure hostname
echo $localHostname > /etc/hostname
sed -i "8i 127.0.1.1 $localHostname.localdomain $localHostname" /etc/hosts

# Installing NetworkManager
pacman -S networkmanager --noconfirm

systemctl disable dhcpcd.service
systemctl disable dhcpcd@enp0s3.service
systemctl enable NetworkManager

# Installing boot manager
if [ $isUEFImode = "true" ]; then
	pacman -S refind-efi --noconfirm
	refind-install --usedefault $bootPart
	if [ -e "/boot/refind_linux.conf" ]; then
		echo "rEFInd installed"
	else
		sysPartUUID=$(blkid -o value -s PARTUUID ${rootPart})
		echo -e "\"Boot with standard options\" \"rw root=PARTUUID=$sysPartUUID rootfstype=xfs add_efi_memmap\"
		\"Boot to single-user mode\" \"rw root=PARTUUID=$sysPartUUID rootfstype=xfs add_efi_memmap single\"
		\"Boot with minimal options\" \"ro root=PARTUUID=$sysPartUUID\"" > /boot/refind_linux.conf
	fi
else
	pacman -S grub --noconfirm
	grub-install --target=i386-pc $bootPart # Command not found
	grub-mkconfig -o /boot/grub/grub.cfg # Command not found
fi
