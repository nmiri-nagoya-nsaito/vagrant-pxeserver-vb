#!/usr/bin/env bash
set -eu

cd /tmp

# import username and password for VM
. /tmp/variables.sh

# install packages
apt-get update
apt-get upgrade -y
apt-get install -y dnsmasq pxelinux syslinux-common openssh-server whois

# TFTP repository
wget -q http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/netboot.tar.gz
mkdir -p /var/lib/tftpboot/
tar xvf netboot.tar.gz -C /var/lib/tftpboot

cat << EOS > /var/lib/tftpboot/pxelinux.cfg/default
path ubuntu-installer/amd64/boot-screens/

menu title Installer boot menu
menu tabmsg Press ENTER to boot or [TAB] to edit options

default auto
label auto
	menu label ^Ubuntu Server 18.04(LTS) auto install
        menu default
        kernel ubuntu-installer/amd64/linux
	append auto=true priority=critical url=tftp://$VAGRANT_PXE_IP/preseed.cfg DEBCONF_DEBUG=5 initrd=ubuntu-installer/amd64/initrd.gz quiet --
label nvme
        menu label ^Ubuntu Server 18.04(LTS) auto install (to NVMe disk)
        menu default
        kernel ubuntu-installer/amd64/linux
        append auto=true priority=critical url=tftp://$VAGRANT_PXE_IP/preseed_nvme.cfg DEBCONF_DEBUG=5 initrd=ubuntu-installer/amd64/initrd.gz quiet --

default ubuntu-installer/amd64/boot-screens/vesamenu.c32
prompt 0
timeout 0
EOS

# dnsmasq (DHCP proxy, TFTP server)
service dnsmasq stop

echo "DNSMASQ_EXCEPT=lo" >> /etc/default/dnsmasq

cat << EOS > /etc/dnsmasq.conf 
port = 0
log-dhcp
dhcp-range=$VAGRANT_PXE_NETIP, proxy
dhcp-boot=pxelinux.0
pxe-service=x86PC,"Network Boot",pxelinux
enable-tftp
tftp-root=/var/lib/tftpboot
EOS

# PreSeed (debian automatic installer)
cat << EOS > /var/lib/tftpboot/preseed.cfg
d-i debian-installer/locale string en_US
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select us
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string unassigned-hostname
d-i netcfg/get_domain string unassigned-domain
d-i netcfg/wireless_wep string
d-i mirror/country string manual
d-i mirror/http/hostname string archive.ubuntu.com
d-i mirror/http/directory string /ubuntu
d-i mirror/http/proxy string
d-i passwd/root-login boolean false
d-i passwd/username string $USER_NAME
d-i passwd/user-fullname string $FULL_NAME
d-i passwd/user-password-crypted password $HASH
d-i user-setup/encrypt-home boolean false
d-i clock-setup/utc boolean true
d-i time/zone string Asia/Tokyo
d-i clock-setup/ntp boolean true
d-i partman-auto/method string lvm
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman-md/confirm boolean true
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i pkgsel/include string openssh-server python
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i finish-install/reboot_in_progress note
EOS

cp /var/lib/tftpboot/preseed.cfg /var/lib/tftpboot/preseed_nvme.cfg
echo "d-i partman-auto/disk string /dev/nvme0n1" >> /var/lib/tftpboot/preseed_nvme.cfg
echo "d-i grub-installer/bootdev  string /dev/nvme0n1" >> /var/lib/tftpboot/preseed_nvme.cfg

service dnsmasq start

exit 0
