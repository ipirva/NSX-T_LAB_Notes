#!/bin/bash

<<'COMMENT'
Ionut Pirva
create ubuntu VM template
COMMENT

set -e -a

# if root, exit
if [ $(id -u) -eq 0 ] ; then 
    echo "Do not run this as root." && exit 1
fi

template_name="Ubuntu_641804Template_DHCP"
cloudimg="bionic-server-cloudimg-amd64.ova" # we will pull this cloudimg Ubuntu 18.04LTS
network_mgmt_name="VM Network" # env specific, vSphere mgmt network
network_mgmt="vi-cluster1-vds-Mgmt" # env specific, vSphere mgmt network
source $HOME/NSX-T_LAB_Notes/vms/govcvars.sh # if git clone was done at the begining, this should be right; edit for any specifics

dir=$(dirname "$0")
cloudinit_path=$HOME/NSX-T_LAB_Notes/vms/cloud-config-dhcp.yaml # if git clone was done at the begining, this should be right; edit for any specifics
cp $HOME/NSX-T_LAB_Notes/vms/cloud-config-dhcp.yaml $HOME/NSX-T_LAB_Notes/vms/cloud-config-dhcp.yaml.orig # save the original cloud config file
mySSHKey=$(cat $HOME/.ssh/my_id_rsa.pub) # the SSH key must have generated at the stagging moment
sed -i "s|- ssh-rsa.*|- $mySSHKey|g" $cloudinit_path
# prepare cloud-init script
# replace username/password, ssh-key ...
# change cloud-config-dhcp.yaml and set users.ssh-authorized-keys
# use the base64 output to set the value for the key "user-data" in ubuntu.json
cloud_init_content=$(base64 -w0 $cloudinit_path)

# download cloudimg
wget -nc https://cloud-images.ubuntu.com/bionic/current/$cloudimg # download the cloudimg Ubuntu 18.04LTS

# the vm folder and resource pool may be created later via terraform as well
govc pool.create /$GOVC_DATACENTER/host/$GOVC_CLUSTER/Resources/$GOVC_RESOURCE_POOL
govc folder.create /$GOVC_DATACENTER/vm/Workloads

govc folder.create $GOVC_TEMPLATES || true
templates=$(govc find $GOVC_TEMPLATES -type m)
for template in "${templates[@]}"; do 
    template_name_found=$(cut -d'/' -f5 <<<"$template")
    if [ "$template_name_found" = "$template_name" ]; then
        govc vm.destroy $template 
    fi
done

govc import.spec bionic-server-cloudimg-amd64.ova | python3 -m json.tool > ubuntu.json
cp ubuntu.json ubuntu.json.orig

cat <<< $(jq -r --arg template_name "$template_name" '.MarkAsTemplate |= false | .PowerOn |= false | .InjectOvfEnv |= false | .WaitForIP |= false | .Name |= $template_name' ubuntu.json) > ubuntu.json
cat <<< $(jq '.DiskProvisioning |= "thin" | .IPAllocationPolicy |= "dhcpPolicy" | .IPProtocol |= "IPv4"' ubuntu.json) > ubuntu.json

# change user-data, hostname and default password
cat <<< $(jq -r --arg cloud_init_content "$cloud_init_content" '(.PropertyMapping[] | select(.Key == "user-data") | .Value) |= $cloud_init_content' ubuntu.json) > ubuntu.json
cat <<< $(jq '(.PropertyMapping[] | select(.Key == "hostname") | .Value) |= "vm_template"' ubuntu.json) > ubuntu.json
cat <<< $(jq '(.PropertyMapping[] | select(.Key == "password") | .Value) |= "VMware123!"' ubuntu.json) > ubuntu.json
# change mgmt network
cat <<< $(jq -r --arg network_mgmt_name "$network_mgmt_name"  --arg network_mgmt "$network_mgmt" '(.NetworkMapping[].Name |= $network_mgmt_name | .NetworkMapping[].Network |= $network_mgmt)'  ubuntu.json) > ubuntu.json

govc import.ova -json=true -folder=$GOVC_TEMPLATES -options=ubuntu.json bionic-server-cloudimg-amd64.ova
govc vm.change -vm $template_name -c 1 -m 2048 -e="disk.enableUUID=1"
govc vm.disk.change -vm $template_name -disk.label "Hard disk 1" -size 10G
govc vm.power -on=true -json=true $template_name
until govc vm.info -json=true $template_name | jq -r '.VirtualMachines[].Runtime.PowerState' | grep -q  "poweredOff"; do sleep 5; done
govc vm.markastemplate $template_name