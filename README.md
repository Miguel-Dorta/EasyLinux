# EasyLinux
Script to make ArchLinux installation simple

### How to use it?
- Boot your system from the Archlinux installation disk.
- Download the script: `wget https://raw.githubusercontent.com/Miguel-Dorta/EasyLinux/master/easylinux.sh`
- Mark it as executable: `chmod +x easylinux.sh`
- Run it: `./easylinux.sh`

## FAQ
### What does this script do?
Under your instructions, it installs Archlinux in your system, following the steps of the [official guide](https://wiki.archlinux.org/index.php/installation_guide "Archlinux installation guide")

### What can I configure with it?
You'll be able to set up:
- Keyboard layout
- Language (main and additionals)
- Time zone
- Hostname

### What is the difference between "Clean" and "Advanced" installation mode?
The clean mode wipes out the entire disk that you define, and then it creates the following partition layout:
| Mount point   | Type                | Size        |
| ------------- |:-------------------:| -----------:|
| /boot         | EFI (FAT32) or ext4 |     512 MiB |
| [SWAP]        | Linux swap          |       2 GiB |
| /             | xfs                 |   Remainder |

The advanced mode brings you the possibility to configure other layout, but it requires to have those partitions already created and formatted. If you find yourself in this step with no partitions created, you can close the script.

### How can I close the script?
Just type `Ctrl+C`.