#!/bin/bash

set -e -a

if_tenant="ens224"
tenant_mtu=9000
icmp_mtu=$(($tenant_mtu-28))

ip link show $if_tenant
# if link exists
if [ $? -eq 0 ]; then
  ip link set $if_tenant down
  ip link set $if_tenant mtu $tenant_mtu
  ip link set $if_tenant up
  sleep 3 # wait 3 seconds for the interface to come up
  tenant_test=$(ip link show $if_tenant | egrep " mtu 9000 .* state UP " | wc -l)
  # if test is successful
  if [ $tenant_test -eq 1 ]; then
    echo "Interface $if_tenant MTU configured correctly."
    ip route add 172.17.0.0/16 via 172.17.20.1 && sleep 3
    exit 0
  else
    echo "Interface $if_tenant MTU not configured correctly." && exit 1
  fi
fi
