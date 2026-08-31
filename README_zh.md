# dotfiles

<img src="./img/scs-full-2026-08-31-10-01-11.png"/>

<p align="center">
  <a href="./README.md">English</a> |
  <a href="./README_zh.md">简体中文</a>
</p>

> [!NOTE]
> - 尽可能极简主义配置
> - 仓库一直在滚动更新
> - 以键盘为中心的操作

## [Arch Linux](https://archlinux.org) 与 [Sway](https://swaywm.org)
我使用archlinux与sway作为桌面环境。archlinux是极简与实用主义的操作系统，它不像其他linux发行版提供开箱即用的体验，archlinux需要你自行配置大部分东西，这对于diy用户非常有意思。sway是xorg下i3的wayland迁移，它配置友好，同时与i3的配置完全通用，你可以直接将i3的配置复制到sway。

## 安装 Arch Linux？
可参考我的archlinux[安装](./arch_install_zh.md)习惯

## 我使用的软件
```sh
# 查看仓库内pkglist.txt文件了解我使用的软件
# 将pkglist.txt输入重定向至pacman可安装列表中的软件
pacman -S --needed - < pkglist.txt
```

## 如何使用？
```sh
# 克隆仓库
git clone https://github.com/bin541/dotfiles.git

# 进入仓库目录
cd ~/path/dotfiles

# 使用stow管理配置
# 创建软链接
stow --adopt -t ~ .

# 删除软链接
stow -D -t ~ .
```

## 许可证
[GNU GPL 3.0](./LICENSE)
```sh
# @author bin
```
