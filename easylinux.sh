#!/bin/bash

# Change working directory
cd /

# Create script folder
mkdir EasyLinux
cd EasyLinux/

# Download scripts
wget https://raw.githubusercontent.com/Miguel-Dorta/EasyLinux/master/scripts/user-inputs.sh
wget https://raw.githubusercontent.com/Miguel-Dorta/EasyLinux/master/scripts/installer.sh
wget https://raw.githubusercontent.com/Miguel-Dorta/EasyLinux/master/scripts/chroot-script.sh
chmod +x *

# Run scripts
./user-inputs.sh
./installer.sh

# Copy and run scripts in the new system
cp -R /EasyLinux/ /mnt/EasyLinux/
arch-chroot /mnt << EOF
	/EasyLinux/chroot-script.sh

	exit
EOF

# Umount partitions & reboot
umount -R /mnt
reboot
