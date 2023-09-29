## Ghostery Browser Linux Support

tl;dr: If you want to install [Ghostery Private Browser](https://www.ghostery.com/ghostery-private-browser) on Linux, here are your options:

On Arch-based distros such as Arch Linux, Manjaro, and EndeavourOS, [use the AUR package](#aur):

```sh
yay -S ghostery-browser-bin
ghostery &
```

Alternatively, use the [Flatpak image](#flatpak). It is supported on all Linux distributions (assuming that `flatpak` is installed):

```sh
flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak --user install com.ghostery.browser

flatpak --user run com.ghostery.browser  # to run it
```

AUR or Flatpak is recommended now, but you can also use the [install script](#installscript):

```sh
curl https://raw.githubusercontent.com/ghostery/ghostery-browser-linux-support/main/install-ghostery.sh | bash
```

It will install the browser in your local user directory.

# Table of contents
1. [Introduction](#introduction)
1. [Flatpak](#flatpak)
1. [AUR installation for Arch-based system (e.g. Arch Linux, Manjaro): ](#aur)
    1. [(Optional) Firejail](#aur-firejail)
1. [Install script for all distros (e.g. Debian, Ubuntu, Mint, Fedora)](#installscript)
1. [Troubleshooting](#troubleshooting)
    1. [Missing dependencies](#missing-dependencies)
    1. [Broken fonts on OpenSUSE](#suse)
1. [(dev only) Vagrant test setup](#vagrant)

### Introduction <a name="introduction"></a>

This is a meta project, which provides an install guide of the Ghostery
Browser for Linux in the form of an install script.

The sources of browser itself can be found in the main repository,
which can be found here:
[user-agent-desktop](https://github.com/ghostery/user-agent-desktop).

If you have generic questions about the Browser itself, please create Github
tickets on the `user-agent-desktop` project. But if you run into Linux-specific
problems, or if you have difficulties with the installation, feel free to
open a ticket here (instead of `user-agent-desktop`).

### Flatpak <a name="flatpak"></a>

Flatpak package: https://flathub.org/apps/com.ghostery.browser

You can install it using the following commands (the first one has to be used
only once if you never added the flathub repository).

```sh
flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak --user install com.ghostery.browser
```

If flatpak is correctly integrated into your desktop environment, you will
find the Ghostery Private Browser in your applications menu. You can also
start it from the command line by using the simple command
`com.ghostery.browser`.

In the contrary, if you did not integrate flatpak inside your desktop, you can
still run it from the command line by using the command:

```sh
flatpak --user run com.ghostery.browser
```

If you want to contribute, more information on the Flatpak package can be found
in its dedicated [README](flatpak/README.md).

### AUR: Arch Based System (Arch Linux, Manjaro, ...) <a name="aur"></a>

If you are on an Arch-based system, which uses `pacman` as the package manager,
it is recommended to use the [AUR package](https://aur.archlinux.org/packages/ghostery-browser-bin/).

For a documentation how to use AUR, refer to the documentation of your distribution:

* Arch: https://wiki.archlinux.org/title/Arch_User_Repository
* Manjaro: https://wiki.manjaro.org/index.php/Arch_User_Repository

For instance, if you are using [`yay`](https://github.com/Jguer/yay):

```sh
yay -S ghostery-browser-bin
```

Now you can start it by running:

```sh
ghostery
```

#### (Optional) Firejail Setup <a name="aur-firejail"></a>

The AUR comes with a setup for [Firejail](https://firejail.wordpress.com/).
If you want to use it, follow the post-install instructions:

```sh
sudo pacman -S firejail
firejail ghostery
```

If you want, you can make it permanent:

```sh
sudo ln -s /usr/bin/firejail /usr/local/bin/ghostery
```

Now running `ghostery` will have the same effect as running
`/usr/bin/firejail /usr/bin/ghostery`.

### Generic Install Script <a name="installscript"></a>

In this repository, you will find `install-ghostery.sh`, which automates
the steps to download the latest binary build and install it for your
local user (in `~/.local/opt` and `~/.local/bin`).

By default, this script will download and install the english version of the
browser. But you can pass a lang code as argument to download another version
of it (currently, only fr, de and en-US versions are available):
`./install-ghostery.sh de`

Once the installation finishes, you should be able to start the browser
by executing: `ghostery` (or as a fallback: `~/.local/bin/ghostery`).

If want to undo the changes made by the installer, you can execute:

```sh
rm -rf ~/bin/ghostery ~/.local/bin/ghostery ~/.local/opt/ghostery/Ghostery ~/.local/share/applications/ghostery-private-browser.desktop
```

### Troubleshooting <a name="troubleshooting"></a>

#### Missing dependencies <a name="missing-dependencies"></a>

It is possible that the Ghostery Browser will not start because dependencies
are missing. As it is a fork of Firefox, it should typically work if you install
Firefox to get all required dependencies:

```sh
sudo apt-get install firefox      # Ubuntu / Mint
sudo apt-get install firefox-esr  # Debian
sudo yum install -y firefox       # Fedora
```

In addition, the installer itself requires `bzip2`, and either `wget` or `curl` to be present.

*For Arch/Manjaro Users*: this section only applies when you used the install script.
If you are using the AUR, it should automatically install all dependencies. If not,
please report it as bug on the
[AUR page](https://aur.archlinux.org/packages/ghostery-browser-bin/),
(and please include the error message).

#### OpenSUSE <a name="suse"></a>

Currently, OpenSUSE is not well supported. Starting with OpenSUSE 15.3, the
browser is able to start, but there  an issue with the fonts.
In older versions (15.2 or earlier), it will not start because the glibc
library is too old (needs to be 2.28).

### Vagrant Test Setup <a name="vagrant"></a>

The rest of the document targets developers: it explains the included Vagrant setup, which can be used to test the installation on various Linux distributions. It includes a ssh setup with X11 forwarding, so you can start the browser by logging in.

You should install [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/). As a quick check, you can try to bring up a Ubuntu machine:

```
vagrant up ubuntu20.04
```

It should finish the installation without errors. Once you are done, you can destroy it again:

```
vagrant destroy ubuntu20.04
```

For more details, read the instructions in the Vagrantfile.
Be careful when starting all machines at the same time (`vagrant up`), as it will require a lot of memory.
