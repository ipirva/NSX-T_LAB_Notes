#!/bin/bash
set -e -a
# govcvars.sh
export GOVC_INSECURE=1 # Don't verify SSL certs on vCenter
export GOVC_URL=vcenter-vsan.vrack.vsphere.local # vCenter IP/FQDN
export GOVC_USERNAME=administrator@vsphere.local # vCenter username
export GOVC_PASSWORD=VMware123! # vCenter password
export GOVC_DATASTORE=vi-cluster1-vSanDatastore # Default datastore to deploy to
export GOVC_NETWORK="vi-cluster1-vds-Mgmt" # Default network to deploy to
export GOVC_RESOURCE_POOL="Compute-Resource-Pool" # Default resource pool to deploy to
export GOVC_DATACENTER=new-vi-DC # I have multiple DCs in this VC, so i'm specifying the default here
export GOVC_TEMPLATES=/$GOVC_DATACENTER/vm/Templates
