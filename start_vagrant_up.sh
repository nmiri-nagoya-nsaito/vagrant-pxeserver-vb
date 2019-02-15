#!/usr/bin/env bash
set -e

# variables
USER_NAME=
FULL_NAME=
pw=
HASH=
bridge_if=
ip_addr=

# username and password for VM
while [ x"$USER_NAME" = "x" ];
do
  read -p "user name for new machine: " USER_NAME
done

while [ x"$FULL_NAME" = "x" ];
do
  read -p "full name for $(eval echo $USER_NAME): " FULL_NAME
done

read -sp "Password for $(eval echo $USER_NAME): "  pw
echo

# generate hash
## OSX
if [ "$(uname)" == 'Darwin' ]; then
  HASH=$(php -r "echo crypt('${pw}','\$6\$'.hash('sha512', uniqid(mt_rand(),true))), PHP_EOL;")

## Linux
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  HASH=$(echo -n $password | mkpasswd -m sha-512)

## other
else
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
fi
password=

echo -n "This machine's IP address: "
ifconfig | grep "inet" | grep -v "127.0.0.1" | grep -v "inet6"
read -p "IP address of VM: " ip_addr
echo

echo "Available Bridge I/F name:"
VBoxManage list bridgedifs | grep "^Name" | awk -F': {12}' '{print $2}'
read -p "Select I/F name(e.g. en0, en1, ..): " bridge_if
echo

echo "Settings: "
echo " User Name: ${USER_NAME}"
echo " Full Name: ${FULL_NAME}"
echo " Pass(Hash): ${HASH}"
echo " Bridge I/F: ${bridge_if}"
echo " IP address: ${ip_addr}"

while :
do
  read -p "Is it OK [y/n]: " ans
  case $ans in
    [yY])
      echo "Starting vagrant up...\n"
      echo "USER_NAME='$USER_NAME'" > variables.sh
      echo "FULL_NAME='$FULL_NAME'" >> variables.sh
      echo "HASH='$HASH'" >> variables.sh
      echo "VAGRANT_PXE_IP='$ip_addr'" >> variables.sh
      VAGRANT_PXE_IP=${ip_addr} VAGRANT_BRIDGE=${bridge_if} vagrant up
      break
      ;;
    [nN])
      echo "abort."
      break
      ;;
    *)
      ;;
  esac
done

exit 0

