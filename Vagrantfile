# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# To start all machines (slow + 32G of memory is recommended):
# $ vagrant up
#
# To start only one specific machine (e.g. Ubuntu):
# $ vagrant up ubuntu20.04
#
# To login and start Ghostery (e.g. Ubuntu):
# $ vagrant ssh ubuntu20.04 -- -X
# vagrant@ubuntu-focal:~$ ghostery &
#
# Or if the path is not set up, use the fallback:
# vagrant@ubuntu-focal:~$ ~/.local/bin/ghostery &
#
# Finally, once you are done, you can destroy all machines:
# $ vagrant destroy -y

VAGRANTFILE_API_VERSION = "2"

def debian_based(configs)
  configs.each { |x| x[:family] = :debian }
  configs
end

def archlinux_based(configs)
  configs.each { |x| x[:family] = :archlinux }
  configs
end

def suse_based(configs)
  configs.each { |x| x[:family] = :suse }
  configs
end

def redhat_based(configs)
  configs.each { |x| x[:family] = :redhat }
  configs
end

# https://app.vagrantup.com/ubuntu
UBUNTU = debian_based [
  { name: "ubuntu20.04", box: "ubuntu/focal64" },
  { name: "ubuntu21.04", box: "ubuntu/hirsute64" },
  { name: "ubuntu21.10", box: "ubuntu/impish64" },
  { name: "ubuntu22.04", box: "ubuntu/jammy64" },
]

# https://app.vagrantup.com/debian
DEBIAN = debian_based [
  { name: "debian11", box: "debian/bullseye64" },
]

MINT = debian_based [
  { name: "mint20", box: "aaronvonawesome/linux-mint-20-cinnamon" }
]

ARCH = archlinux_based [
  { name: "archlinux", box: "archlinux/archlinux" },
  { name: "manjaro", box: "Zelec/manjarolinux" },
]

# https://app.vagrantup.com/opensuse/
#
# SUSE is currently not well supported:
# * 15.2 still uses glibc 2.26, which is not supported.
#   We need at least 2.28, which comes with 15.3.
# * With a recent version, the browser opens but the fonts are broken.
SUSE = suse_based [
  { name: "suse-15.3", box: "opensuse/Leap-15.3.x86_64" },
  { name: "suse-tumbleweed", box: "opensuse/Tumbleweed.x86_64" },
]

# https://app.vagrantup.com/fedora
FEDORA = redhat_based [
  { name: "fedora35", box: "fedora/35-cloud-base" },
]

# Disabled for now (try Fedora instead). The reason is that RHEL needs
# additional setup to install the required dependencies.
REDHAT = redhat_based [
  { name: "rhel8", box: "generic/rhel8" },
]

#ALL_PLATFORMS = UBUNTU + MINT + DEBIAN + ARCH + SUSE + FEDORA + REDHAT
SUPPORTED_PLATFORMS = UBUNTU + MINT + DEBIAN + ARCH + FEDORA

DEBIAN_TESTING_SETUP = <<-SHELL
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y xauth
SHELL

ARCH_TESTING_SETUP = <<-SHELL
  if [[ -e /etc/manjaro-release ]]; then
    # Note: the default mirror in the Manjaro box is extremely slow.
    # Thus, replace the mirror by faster ones:
    pacman-mirrors --timeout 1 --fasttrack 3 && pacman --noconfirm --disable-download-timeout -Syyu
  else
    pacman --noconfirm --disable-download-timeout -Syu
  fi
  pacman --noconfirm --disable-download-timeout -S xorg-xauth
  echo "X11Forwarding yes" > /etc/ssh/sshd_config
  systemctl restart sshd
SHELL

SUSE_TESTING_SETUP = <<-SHELL
  zypper --non-interactive refresh
  zypper --non-interactive install xauth
SHELL

REDHAT_TESTING_SETUP = <<-SHELL
  yum install -y xorg-x11-xauth
SHELL

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Installation in the home directory through the generic install script:
  SUPPORTED_PLATFORMS.each do |platform|
    config.vm.define platform[:name] do |app|
      app.vm.box = platform[:box]

      app.vm.provider "virtualbox" do |vb|
        # Display the VirtualBox GUI when booting the machine
        #vb.gui = true

        # Customize the amount of memory on the VM:
        vb.memory = "1024"
      end

      case platform[:family]
      when :debian
        app.vm.provision "shell", inline: DEBIAN_TESTING_SETUP
        app.vm.provision "shell", inline: <<-SHELL
           # dependencies that the user should install
           DEBIAN_FRONTEND=noninteractive apt-get install -y wget
           if [[ $(lsb_release -i -s) == Debian ]]; then
             DEBIAN_FRONTEND=noninteractive apt-get install -y firefox-esr
           else
             DEBIAN_FRONTEND=noninteractive apt-get install -y firefox
           fi
        SHELL
      when :archlinux
        app.vm.provision "shell", inline: ARCH_TESTING_SETUP
        app.vm.provision "shell", inline: <<-SHELL
          # dependencies that the user should install
          pacman --noconfirm --disable-download-timeout -S firefox
        SHELL
      when :suse
        app.vm.provision "shell", inline: SUSE_TESTING_SETUP
        app.vm.provision "shell", inline: <<-SHELL
          # dependencies that the user should install
          zypper --non-interactive install MozillaFirefox
        SHELL
      when :redhat
        app.vm.provision "shell", inline: REDHAT_TESTING_SETUP
        app.vm.provision "shell", inline: <<-SHELL
          # dependencies that the user should install
          yum install -y firefox
        SHELL
      end

      app.vm.provision "file", source: "./install-ghostery.sh" , destination: "/home/vagrant/install-ghostery.sh"
      app.vm.provision "shell", inline: "su - vagrant -c '/bin/bash /home/vagrant/install-ghostery.sh'"
    end
  end

  # Arch specific installation through the AUR package:
  # https://aur.archlinux.org/packages/ghostery-dawn-bin/
  ARCH.each do |platform|
    config.vm.define "#{platform[:name]}-aur" do |app|
      app.vm.box = platform[:box]

      app.vm.provider "virtualbox" do |vb|
        # Display the VirtualBox GUI when booting the machine
        #vb.gui = true

        # Customize the amount of memory on the VM:
        vb.memory = "1024"
      end

      app.vm.provision "shell", inline: ARCH_TESTING_SETUP
      app.vm.provision "shell", inline: <<-SHELL
        # setup yay (for AUR)
        pacman --noconfirm --disable-download-timeout -S --needed git base-devel
        ( su vagrant /bin/bash -c 'git clone https://aur.archlinux.org/yay.git && cd yay && makepkg --noconfirm -si' )

        # install Ghostery from aur/ghostery-dawn-bin
        su vagrant /bin/bash -c 'yay --noconfirm -S ghostery-dawn-bin'
      SHELL
    end
  end
end
