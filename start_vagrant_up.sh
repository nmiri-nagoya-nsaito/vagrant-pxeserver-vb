#!/usr/bin/env bash
set -e

# functions

# IP addr -> 32bit decimal
function ip2dec(){
  local IFS=.
  local c=($1)
  printf "%s\n" $(( (${c[0]} << 24) | (${c[1]} << 16) | (${c[2]} << 8) | ${c[3]} ))
}

# 32bit decimal -> IP addr
function dec2ip(){
  local n=$1
  printf "%d.%d.%d.%d\n" $(($n >> 24)) $(( ($n >> 16) & 0xFF)) $(( ($n >> 8) & 0xFF)) $(($n & 0xFF))
}

# variables
USER_NAME=
FULL_NAME=
pw=
HASH=
bridge_if=
ip_addr=
host_ip=
net_mask=
net_ip=

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
read -p "IP address of target VM: " target_ip
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
echo " IP address: ${target_ip}"

while :
do
  read -p "Is it OK [y/n]: " ans
  case $ans in
    [yY])
      # calculate target network address
      target_ip_dec=$(ip2dec $target_ip)

      for i in $(ifconfig | grep "inet" | grep -v "inet6" | grep -v "127.0.0.1" | awk '{print $2}')
      do
        echo "for $i:"
        host_ip_dec=$(ip2dec $(ifconfig | grep $i | awk '{print $2}'))
        net_mask_dec=$(printf "%d" $(ifconfig | grep $i | awk '{print $4}'))
        net_ip_dec=$((host_ip_dec&net_mask_dec))
        target_net_ip_dec=$((target_ip_dec&net_mask_dec))

        net_ip=$(dec2ip $net_ip_dec)
        echo "host network address: $net_ip"

        if [ $net_ip_dec -eq $target_net_ip_dec ]; then
          echo "$net_ip may be a network address of target machine."
          break
        else
          echo "$net_ip may not be a network address of target machine."
          net_ip=
        fi
      done

      ## start vagrant
      echo "Starting vagrant up..."
      echo "USER_NAME='$USER_NAME'" > variables.sh
      echo "FULL_NAME='$FULL_NAME'" >> variables.sh
      echo "HASH='$HASH'" >> variables.sh
      echo "VAGRANT_PXE_IP='$target_ip'" >> variables.sh
      echo "VAGRANT_PXE_NETIP='$net_ip'" >> variables.sh
      VAGRANT_PXE_IP=${target_ip} VAGRANT_BRIDGE=${bridge_if} vagrant up
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

