# vagrant-pxeserver-vb
Vagrant scripts for PXE server VM on VirtualBox

# How to use

## download files
```
$ git clone https://github.com/nmiri-nagoya-nsaito/vagrant-pxeserver-vb.git
$ cd vagrant-pxeserver-vb
```

## create and start VM
```
$ ./start_vagrant_up.sh 
user name for new machine: saito
full name for saito: Naoki Saito
Password for saito: 
This machine's IP address: 	inet 172.23.0.100 netmask 0xffff0000 broadcast 172.23.255.255
IP address of VM: 172.23.0.99

Available Bridge I/F name:
en4: Thunderbolt Ethernet
en0: Wi-Fi (AirPort)
en1: Thunderbolt 1
bridge0
p2p0
awdl0
Select I/F name(e.g. en0, en1, ..): en4

Settings: 
 User Name: saito
 Full Name: Naoki Saito
 Pass(Hash): <password hash>
 Bridge I/F: en4
 IP address: 172.23.0.99
Is it OK [y/n]: y
Starting vagrant up...\n
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'ubuntu/bionic64'...
(...snip...)
    default: ./ubuntu-installer/amd64/boot-screens/libcom32.c32
    default: ./ubuntu-installer/amd64/boot-screens/f5.txt
    default: ./ubuntu-installer/amd64/pxelinux.0
    default: ./pxelinux.0
```

## boot a new machine which Ubuntu Server is installed to

The machine needs to be enabled network boot.
When starting up, ubuntu installer will run automatically.
After Instalation is completed, disable network boot and reboot the machine.

## re-provision VM
```
$ vagrant up --provision
```

## shutdown VM
```
$ vagrant halt
==> default: Attempting graceful shutdown of VM...
```

## delete VM
```
$ vagrant destroy
    default: Are you sure you want to destroy the 'default' VM? [y/N] y
==> default: Destroying VM and associated drives...
```
