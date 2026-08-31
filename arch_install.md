# Arch Linux
I am performing a full-disk installation of Arch Linux on a single drive in a laptop, encrypting the entire drive with automatic TPM chip decryption, and configuring Secure Boot using sbctl (signing/verifying the kernel in the boot partition...).

- Platform: Laptop x86_64
- Firmware: UEFI
- Storage: SSD
- Security Chip: TPM 2.0
- Disk Encryption: crypt
- Bootloader: systemd-boot
- Kernel: linux-arch
- Secure Boot: sbctl

## 0.Preparation
[Download](https://archlinux.org/download/) the Arch Linux ISO file.

Verify that the file has not been modified, such as by verifying the hash value:
```sh
sha256 archlinux-2026.1.1-x86_64.iso
```

Create an Arch Linux installation USB drive; I use [Ventoy.](https://www.ventoy.net).

Enter UEFI, disable Secure Boot to enter Setup Mode, and clear existing keys.

Insert the installation USB drive and boot from it.

Connect an Ethernet cable for a wired connection, or use iwctl to connect to a Wi-Fi network:
```sh
iwctl
     [iwd]# device list
     [iwd]# station DEVICE scan
     [iwd]# station DEVICE get-networks
     [iwd]# station DEVICE connect SSID
```

Since I am in Mainland China, I use the Alibaba Cloud mirror to speed up the download:
```sh
echo 'Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
```

Update the local repository metadata and update the archlinux-keyring package:
```sh
pacman -Syy
pacman -S archlinux-keyring
``` 

## 1.Encryption and Partitioning
I will create a GPT partition table on the first drive (nvme0n1) and divide it into nvme0n1p1 (FAT32 filesystem, used as the boot partition and configured for Secure Boot with sbctl) and nvme0n1p2 (ext4 filesystem, used as the root / partition with full-disk encryption via crypt).  
Use cfdisk to create the GPT partition table and partition the drive:
```sh
cfdisk /dev/nvme0n1
```
Encrypt the nvme0n1p2 partition and open it. Think of a complex passphrase. The encrypted nvme0n1p2 partition will be mapped to /dev/cryptroot:
```sh
cryptsetup luksFormat /dev/nvme0n1p2 
cryptopen /dev/nvme0n1p2 cryptroot
```

Create filesystems:
```sh
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 /dev/mapper/cryptroot
```

Mount the root (/) partition and the boot partition:
```sh
mount /dev/mapper/cryptroot /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

View partition structure
```sh
lsblk -f
```

## 2.Swap File
Create a swap file, choosing a size based on your physical RAM capacity (e.g., 16G):
```sh
fallocate -l 16G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
```

## 3.Install the Base System
- I use an AMD processor, so I install the amd-ucode microcode. If using Intel, it would be intel-ucode. If you are in a virtual machine, you don't need to install microcode.
- linux-firmware contains firmware for all platforms. If you know the specific firmware packages your computer needs, you can install them individually, e.g., linux-firmware-amdgpu / linux-firmware-intel / ...
```sh
pacstarp -K /mnt base base-devel linux linux-firmware amd-ucode sbctl vim bash-completion ufw networkmanager bluez
``` 

Write the partition layout to the fstab file:
```sh
genfstab -U /mnt >> /mnt/etc/fstab
```

## 4.Enter the Base System
```sh
arch-chroot /mnt
```

Synchronize the hardware clock. I use the Asia/Shanghai time zone:
```sh
ln -sf /usr/share/zoninfo/Asia/Shanghai/ /etc/localtime
hwclock -systohc
```

Hostname:
```sh
echo 'myarchlinux' > /etc/hostname
``` 

Append DNS resolution:
```sh
vim /etc/hosts
127.0.0.1 localhost
::1 localhost
+127.0.1.1 myarchlinux.localdomain myarchlinux
``` 

Localization:
```sh
vim /etc/locale.gen
-#en_US.UTF-8 UTF-8
+en_US.UTF-8 UTF-8
locale-gen
echo 'LANG=en_us.UTF-8' > locale.conf
```

Create a user account and add it to the wheel group:
```sh
useradd -G wheel -m username
passwd username
visudo
-#%wheel ALL=(ALL:ALL) ALL
+%wheel ALL=(ALL:ALL) ALL
```

## 5.Bootloader
*? (Optional) Alternatively, you can skip the bootloader and boot the kernel directly from UEFI using a [Unified Kernel Image (UKI)](https://wiki.archlinux.org/title/Unified_kernel_image).*  
Install systemd-boot and create the loader.conf file:
```sh
bootctl install
vim /boot/loader/loader.conf
+default arch
+editor no
-#timeout 3
+timeout 0
```

Create a boot entry:
```sh
echo "PARTUUID=$(blkid -s PARTUUID -o value /dev/nvme0n1p2)" > /etc/arch.conf
vim /boot/loader/entries/arch.conf
+title   Arch Linux
+linux   /vmlinuz-linux
+initrd  /amd-ucode.img
+initrd  /initramfs-linux.img
+options root=PARTUUID=yourUUID rw quiet
```
*? (Optional) On a single drive with a GPT partition table, you can use Discoverable Partitions Specification [(GPT partition automounting)](https://wiki.archlinux.org/title/Systemd#GPT_partition_automounting) without needing a UUID. However, in some cases, GPT auto-mounting may not work, and a UUID will be required.*
```sh
vim /boot/loader/entries/arch.conf
+title   Arch Linux
+linux   /vmlinuz-linux
+initrd  /amd-ucode.img
+initrd  /initramfs-linux.img
+options rw quiet
```

## 6.initramfs
Edit the /etc/mkinitcpio.conf file and add the sd-encrypt hook:
```sh
vim /etc/mkinitcpio.conf
-HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems fsck)
+HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
```

Generate the initramfs:
```sh
mkinitcpio -P
```

## 7.Secure Boot
Ensure that Secure Boot is disabled to enter Setup Mode and the existing keys have been cleared. You will need to enable Secure Boot in your UEFI settings after rebooting the system.
```sh
sbctl status
sbctl create-keys
sbctl enroll-keys -m
sbctl sign -s /boot/vmlinuz-linux
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
```

## 8.TPM
Bind to the TPM chip; you will need to enter the encryption passphrase you just created:
```sh
systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
```

## 9.Services
Enable the firewall, network, Bluetooth, and time synchronization services to start on boot:
```sh
systemctl enable ufw NetworkManager bluetooth systemd-timesyncd
```

## *?.（Optional）*
*If you use my dotfiles, you need to install some additional software:*
```sh
# Install git
pacman -S git

# Clone
git clone https://github.com/bin541/dotfiles.git

# Enter the repository directory 
cd ~/path/dotfiles

# Redirect the pkglist.txt file from the repository into pacman to install the listed packages
pacman -S --needed - < pkglist.txt

# Use stow to manage configurations
# Create symbolic links
stow --adopt -t ~ .

# Remove symbolic links
stow -D -t ~ .

# Enable on boot
systemctl enable keyd 
# These services need to be started after entering the installed system
sudo systemctl enable --now mpd mpd-mpris
```

## 10.Complete
```sh
# Exit arch-chroot
exit

# Unplug the USB drive

# Reboot / Power off
reboot
Power
```
