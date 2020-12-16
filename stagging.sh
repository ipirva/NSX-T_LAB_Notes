#!/bin/bash

<<'COMMENT'
Ionut Pirva
stage a jmp env
COMMENT

set -e -a

my_user="ipirva" # if the script is executed as root, I will create my_user
github_repo_1="https://github.com/ipirva/NSX-T_LAB_Notes.git"
# github_repo_2="https://github.com/ipirva/TKG_LAB_Notes.git"

# install govc
govc_version=0.23.0
govc_url="https://github.com/vmware/govmomi/releases/download/v${govc_version}/govc_linux_amd64.gz"
govc_path="/usr/bin"
# terraform version for pre-compiled installation
terraform_version="0.13.5"

# create a non-root user for the stagging
if [[ $(id -u) -eq 0 ]] ; then 
    # do not run as a root
    id -u $my_user &>/dev/null || useradd -m -r -s /bin/bash $my_user && usermod -a -G wheel $my_user
    my_user_home=$(getent passwd $my_user | cut -d: -f6 | grep "${my_user}$" | xargs)
    # sudo without password
    echo "${my_user} ALL=(ALL) NOPASSWD: ALL" >> ./${my_user}
    chown root:root ./${my_user}
    mv -f ./${my_user} /etc/sudoers.d/
    # create user's home, if it does not exist
    if [ $(echo $my_user_home | wc -w) -eq 1 ]; then
        ls -la $my_user_home &>/dev/null || mkdir -p $my_user_home && chown -R $(id -u $my_user):$(id -g $my_user) $my_user_home
        # run the rest of the script as the newly created user
        exec su "$my_user" "$0" -- "$@"
        cd $HOME
    fi
fi

# if still root, exit
if [ $(id -u) -eq 0 ] ; then 
    echo "Do not run this as root." && exit 1
fi

# execute the rest of the stagging as the non-root user

# read the linux release
if command -v lsb_release; then
    release=$(lsb_release -i) && release=${release,,}
    distro=$(echo $release | grep -Poi 'distributor id:\s+\K([a-zA-Z]+)')
elif test -f "/etc/lsb-release"; then
    # vmware photon os
    release=$(cat /etc/lsb-release | grep -i 'DISTRIB_ID=' | cut -d'=' -f2 | sed s/\"//g) && release=${release,,}
    distro=$release
else
    echo "Cannot determine which release of linux is running." && exit 1
fi

# generate SSH key pair
rm -rf $HOME/.ssh/my_id_rsa* && ssh-keygen -t rsa -b 4096 -q -f "$HOME/.ssh/my_id_rsa" -N "" && chmod 0600 $HOME/.ssh/my_id_rsa && chmod 0644 $HOME/.ssh/my_id_rsa.pub

# install CentOS packages
if [ "$distro" = "centos" ]; then
    sudo yum update -y -q -e 0 && sudo yum upgrade -y -q -e 0
    sudo yum install -y -q -e 0 jq git curl wget vim unzip yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && sudo yum -y -q -e 0 install terraform
    # install govc
    curl -sL $govc_url -o $HOME/govc.gz && gunzip -f $HOME/govc.gz && sudo mv $HOME/govc ${govc_path} && sudo chmod +x ${govc_path}/govc && sudo chown root:root ${govc_path}/govc
    # clean yum cache
    sudo yum clean all
fi

if [ "$distro" = "vmware photon os" ]; then
    sudo tdnf -q upgrade && sudo tdnf -q install jq git curl wget vim unzip
    # install govc
    curl -sL $govc_url -o $HOME/govc.gz && gunzip -f $HOME/govc.gz && sudo mv $HOME/govc ${govc_path} && sudo chmod +x ${govc_path}/govc && sudo chown root:root ${govc_path}/govc
    # clean tdnf cache
    sudo tdnf clean all
    # install terraform
    wget -nc https://releases.hashicorp.com/terraform/$terraform_version/terraform_${terraform_version}_linux_amd64.zip && unzip terraform_${terraform_version}_linux_amd64.zip
    chmod +x terraform && sudo chown root:root terraform && sudo mv terraform /usr/bin
fi
cd $HOME
git clone $github_repo_1 || true
# git clone $github_repo_2 || true