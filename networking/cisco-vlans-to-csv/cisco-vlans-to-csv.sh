#!/bin/bash
#
# (c) Michal "Šruby" Šrubař, michal.srubar@greycortex.com, 26th November 2020
#

if [ -z "$1" ] || [ "$1" = "-h" ];
#if  "$1" = "-h" ];
then
  cat << EOF
Cisco running config saves infomation about VLANs and IPs set on a switch
for a specific VLAN in a format that looks as following:

  interface Vlan24
    description phones
    mtu 9216
    ip dhcp relay information trusted
    ip address 192.168.24.254 255.255.255.0

I often need just a description or vlan-id and the network ip plus prefix in
*.csv format. The script will read the file and output such *.csv. The ouput
for the example above would be:

  phones,192.168.24.0/24
EOF

  echo
  echo "Usage: $0 <input-file>"
  exit 1
fi

# Print the single *.csv line
# $1 VLAN
# $2 DESC
# $3 ADDR
function printCsvLine {
  if [ -z "$3" ]; then
    # skip the first call when we have nothing saved
    return
  else
    # prefer desctiption instead of VLAN ID
    if [ -z "$1" ]; then
      echo -n $2,
    else
      echo -n $1,
    fi

    # "ip address 192.168.254.242 255.255.255.252" -> 192.168.254.240/30
    IPANDMASK=`echo "$3" | sed 's/ip address //'`
    ipcalc --no-decorate $IPANDMASK | sed -n '2p'
  fi
}

VLAN=""
DESC=""
ADDR=""
 
# Read the input file line by line. We are only interested in lines containing
# keywords as interface, description or ip address. Othe lines are skipped. We
# use inteface keyword as a start of a new block.
while read line;
do
  if [[ "$line" == interface* ]]; then
    # a new block is starting, print the previous one if any
    printCsvLine "$VLAN" "$DESC" "$ADDR"
    # get and save VLAN id in case there is no description
    VLAN=${line:10}
    DESC=""
    continue
  elif [[ "$line" == description* ]]; then
    # spaces at the begining are striped by read line
    DESC=${line:12}
    VLAN=""   # use description instead of VLAN ID
    continue
  elif echo "$line" | grep -q "ip address"; then
    ADDR=$line
    continue
  else
    continue # skip any other lines like mtu, dhcp relay, etc.
  fi

done < $1

printCsvLine "$VLAN" "$DESC" "$ADDR"
