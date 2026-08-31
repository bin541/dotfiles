# Arch Linux
我在笔记本电脑单块硬盘上全盘安装archlinux，并对硬盘全盘加密同时使用TPM芯片对硬盘自动解密，以及使用sbctl配置安全启动（签名\验证boot分区的内核...）

- 平台：笔记本x86_64
- 主板固件：UEFI
- 硬盘：SSD
- 安全芯片：TPM2.0
- 硬盘加密：crypt
- 引导加载程序：systemd-boot
- 内核：linux-arch 
- 安全启动：sbctl

## 0.准备
[下载](https://archlinux.org/download/)archlinux镜像文件

验证文件是否被修改，如验证哈希值
```sh
sha256 archlinux-2026.1.1-x86_64.iso
```

制作archlinux安装u盘，我使用[Ventoy](https://www.ventoy.net)

进入UEFI关闭安全启动以进入设定模式，并清除原有密钥

插入安装u盘并从u盘启动

插入网线使用有线网络\iwctl连接无线网络
```sh
iwctl
     [iwd]# device list
     [iwd]# station DEVICE scan
     [iwd]# station DEVICE get-networks
     [iwd]# station DEVICE connect SSID
```

我在中国大陆，使用阿里云镜像加速下载
```sh
echo 'Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
```

更新本地仓库元数据并更新archlinux-keyring软件包
```sh
pacman -Syy
pacman -S archlinux-keyring
``` 

## 1.加密与分区
我对nvme0n1机器上第一块硬盘创建GPT分区表并分出nvme0n1p1（fat32文件系统，作为boot分区并使用sbctl配置安全启动）与nvme0n1p2（ext4文件系统，作为/根分区并使用crypt进行全盘加密  
cfdisk对硬盘创建GPT分区表并分区
```sh
cfdisk /dev/nvme0n1
```

加密nvme0n1p2分区并打开该加密分区，想一个复杂密码，加密的nvme0n1p2分区将被映射至/dev/cryptroot
```sh
cryptsetup luksFormat /dev/nvme0n1p2 
cryptopen /dev/nvme0n1p2 cryptroot
```

创建文件系统
```sh
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 /dev/mapper/cryptroot
```

挂载/根分区与boot分区
```sh
mount /dev/mapper/cryptroot /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

查看分区结构
```sh
lsblk -f
```

## 2.交换文件
创建交换文件，根据物理内存容量选择大小，如16g
```sh
fallocate -l 16G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
```

## 3.安装基本系统
- 我使用amd处理器，安装amd-ucode微码，如果是intel，则为intel-ucode，在虚拟机中则不用安装微码
- linux-firmware包含所有平台固件，如你清楚自己电脑所需的详细固件包可单独安装，如：linux-firmware-amdgpu \ linux-firmware-intel \ ...
```sh
pacstarp -K /mnt base base-devel linux linux-firmware amd-ucode sbctl vim bash-completion ufw networkmanager bluez
``` 

将分区结构写入fstab文件
```sh
genfstab -U /mnt >> /mnt/etc/fstab
```

## 4.进入基本系统
```sh
arch-chroot /mnt
```

同步硬件时钟，我使用亚洲上海时区
```sh
ln -sf /usr/share/zoninfo/Asia/Shanghai/ /etc/localtime
hwclock -systohc
```

主机名
```sh
echo 'myarchlinux' > /etc/hostname
``` 

追加dns解析
```sh
vim /etc/hosts
127.0.0.1 localhost
::1 localhost
+127.0.1.1 myarchlinux.localdomain myarchlinux
``` 

本地化
```sh
vim /etc/locale.gen
-#en_US.UTF-8 UTF-8
+en_US.UTF-8 UTF-8
locale-gen
echo 'LANG=en_us.UTF-8' > locale.conf
```

创建账户并加入wheel组
```sh
useradd -G wheel -m username
passwd username
visudo
-#%wheel ALL=(ALL:ALL) ALL
+%wheel ALL=(ALL:ALL) ALL
```

## 5.引导加载程序
*？(可选) 也可不使用引导加载程序，通过[统一内核映像UKI](https://wiki.archlinuxcn.org/wiki/%E7%BB%9F%E4%B8%80%E5%86%85%E6%A0%B8%E6%98%A0%E5%83%8F)从UEFI直接启动内核。*  
安装systemd-boot并创建loader.conf文件
```sh
bootctl install
vim /boot/loader/loader.conf
+default arch
+editor no
-#timeout 3
+timeout 0
```

创建启动条目
```sh
echo "PARTUUID=$(blkid -s PARTUUID -o value /dev/nvme0n1p2)" > /etc/arch.conf
vim /boot/loader/entries/arch.conf
+title   Arch Linux
+linux   /vmlinuz-linux
+initrd  /amd-ucode.img
+initrd  /initramfs-linux.img
+options root=PARTUUID=yourUUID rw quiet
```
*?（可选）在单块GPT分区表硬盘上可使用[GPT分区自动挂载](https://wiki.archlinuxcn.org/wiki/Systemd#GPT%E5%88%86%E5%8C%BA%E8%87%AA%E5%8A%A8%E6%8C%82%E8%BD%BD)，无需uuid，某些情况下无法使用GPT分区自动挂载，需要uuid*
```sh
vim /boot/loader/entries/arch.conf
+title   Arch Linux
+linux   /vmlinuz-linux
+initrd  /amd-ucode.img
+initrd  /initramfs-linux.img
+options rw quiet
```

## 6.initramfs
编辑/etc/mkinitcpio.conf文件，添加sd-encrypt参数
```sh
vim /etc/mkinitcpio.conf
-HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems fsck)
+HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
```

生成initramfs
```sh
mkinitcpio -P
```

## 7.安全启动
确保已关闭安全启动进入设定模式并清除原有密钥，重启系统后需打开安全启动
```sh
sbctl status
sbctl create-keys
sbctl enroll-keys -m
sbctl sign -s /boot/vmlinuz-linux
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
```

## 8.可信平台模块
绑定TPM芯片，需要输入刚创建的加密密码
```sh
systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
```

## 9.服务
将防火墙、网络、蓝牙、时间同步，加入开机自启动
```sh
systemctl enable ufw NetworkManager bluetooth systemd-timesyncd
```

## *?.（可选）*
*如果你使用我的dotfiles，你需要补充一些软件*
```sh
# 安装git
pacman -S git

# 克隆仓库
git clone https://github.com/bin541/dotfiles.git

# 进入仓库目录
cd ~/path/dotfiles

# 将仓库内pkglist.txt文件输入重定向至pacman可安装列表中的软件
pacman -S --needed - < pkglist.txt

# 使用stow管理配置
# 创建软链接
stow --adopt -t ~ .

# 删除软链接
stow -D -t ~ .

# 开机自启动
systemctl enable keyd 
# 这些服务需进入安装完成的系统后启动
sudo systemctl enable --now mpd mpd-mpris
```

## 10.完成
```sh
# 退出arch-chroot
exit

# 拔出u盘

# 重启\关机
reboot
poweroff
```
