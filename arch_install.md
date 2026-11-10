# Install Arch Linux

- Platform: Laptop
- Architecture: x86_64
- Firmware: UEFI
- Drive: SSD
- Security: TPM 2.0
- Boot: systemd-boot
- Kernel: linux

## 0. Preparation
[Download](https://archlinux.org/download/) the Arch Linux image file.

Verify the hash value:
```sh
sha256 archlinux-2027.1.1-x86_64.iso
```

Create an installation USB drive with [Ventoy](https://www.ventoy.net).

Enter UEFI, disable Secure Boot to enter Setup Mode, and clear existing keys.

Boot from the USB drive.

Connect an Ethernet cable to use the wired network.

Use iwctl to connect to a wireless network:
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
pacman -Syyu archlinux-keyring
``` 

## 1. Partitioning and Encryption
Partition:
```sh
cfdisk /dev/nvme0n1
```

Encrypt the nvme0n1p2 partition and open the encrypted partition. Choose a complex passphrase. The encrypted nvme0n1p2 partition will be mapped to /dev/cryptroot:
```sh
cryptsetup luksFormat /dev/nvme0n1p2 
cryptsetup open /dev/nvme0n1p2 cryptroot
```

Create filesystems:
```sh
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 /dev/mapper/cryptroot
```

Mount the root partition and the boot partition:
```sh
mount /dev/mapper/cryptroot /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

View partition structure
```sh
lsblk -f
NAME        FSTYPE      FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
nvme0n1
├─nvme0n1p1 vfat        FAT32       FB20-D290                             442.9M    13% /boot
├─nvme0n1p2 crypto_LUKS 2           17403bc5-d9f0-4890-b8db-b12ba0c3c5e4
└─root      ext4        1.0         146b289d-f442-4a11-b8cb-303cb9a3fb77    1.1T    16% /
```

## 2. Swap File
Create a swap file, choosing a size based on your physical RAM capacity (e.g., 16G):
```sh
fallocate -l 16G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
```

## 3. Install the Base System
- Install CPU microcode: intel-ucode or amd-ucode. You do not need to install microcode in a virtual machine.
- linux-firmware contains firmware for all platforms. If you know the specific firmware packages your computer needs, you can install them individually, e.g., linux-firmware-amdgpu / linux-firmware-intel / ...
```sh
pacstrap -K /mnt base base-devel linux amd-ucode linux-firmware sbctl vim bash-completion ufw networkmanager bluez
``` 

Write the partition layout to the fstab file:
```sh
genfstab -U /mnt >> /mnt/etc/fstab
```

## 4. Enter the Base System
```sh
arch-chroot /mnt
```

Synchronize the hardware clock. I use the Asia/Shanghai time zone:
```sh
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
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
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

Create a user account and add it to the wheel group:
```sh
useradd -G wheel -m username
passwd username
visudo
-#%wheel ALL=(ALL:ALL) ALL
+%wheel ALL=(ALL:ALL) ALL
```

## 5. Bootloader
*Alternatively, use a [Unified Kernel Image (UKI)](https://wiki.archlinux.org/title/Unified_kernel_image) to boot the kernel directly from UEFI.*

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
*For a system installed on a single drive, the boot entry can be simplified with [GPT partition automounting](https://wiki.archlinux.org/title/Systemd#GPT_partition_automounting).*
```sh
vim /boot/loader/entries/arch.conf
+title   Arch Linux
+linux   /vmlinuz-linux
+initrd  /amd-ucode.img
+initrd  /initramfs-linux.img
+options rw quiet
```

## 6. initramfs
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

## 7. Secure Boot
Ensure that Secure Boot is disabled to enter Setup Mode and the existing keys have been cleared. You will need to enable Secure Boot in your UEFI settings after rebooting the system.
```sh
sbctl status
sbctl create-keys
sbctl enroll-keys -m
sbctl sign -s /boot/vmlinuz-linux
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
```

## 8. TPM Trusted Platform Module
Bind the TPM chip; you will need to enter the encryption passphrase you created:
```sh
systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
```

## 9. Services
Enable the firewall, network, Bluetooth, and time synchronization services to start on boot:
```sh
systemctl enable ufw NetworkManager bluetooth systemd-timesyncd
```

## dotfiles
*If you use my dotfiles, you need to install some additional software.*
```sh
pacman -S git

git clone https://github.com/bin541/dotfiles.git

cd ~/path/dotfiles

pacman -S --needed - < pkgs.list

# Manage configuration files with stow
# Create symbolic links
stow --adopt -t ~ .

# Remove symbolic links
stow -D -t ~ .

# Enable system-level services on boot
systemctl enable keyd 

# Enable user-level services on boot
systemctl --user enable --now mpd mpd-mpris
```

## 10. Complete
```sh
# Exit arch-chroot
exit

# Unplug the USB drive

# Reboot / Power off
reboot
poweroff
```
