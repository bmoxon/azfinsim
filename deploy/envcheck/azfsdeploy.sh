#! /bin/bash

# from https://docs.microsoft.com/en-us/azure/bastion/create-host-cli

pfx="azfsdeploy"
rg=bcm-${pfx}-rg
loc="westus2"
vnet_cidr="10.0.0.0/16"
bastion_cidr="10.0.0.0/24"
deploy_cidr="10.0.1.0/24"
vmadminuser="deploy"
vmadminpass="Azfinsimdeploy1"
sshkey=~/.ssh/id_rsa.pub

#seperate vnet peered with 10 for deployment only (?)
#but still need a jumpbox i think, so maybe not ...
#vnet_cidr="172.18.0.0/16"
#bastion_cidr="172.18.0.0/24"
#deploy_cidr="172.18.1.0/24"

az group create \
        --location $loc --resource-group ${rg}

az network vnet create \
        --location ${loc} --resource-group ${rg} \
        --name ${pfx}-vnet \
        --address-prefix ${vnet_cidr}

# public IP for the NAT GW

az network public-ip create \
        --location ${loc} --resource-group ${rg} \
        --name ${pfx}-nat-pubip \
        --sku standard \
        --allocation static

az network nat gateway create \
    --location ${loc} --resource-group ${rg} \
    --name ${pfx}-natgw \
    --public-ip-addresses ${pfx}-nat-pubip \
    --idle-timeout 10 

# deploy subnet with NAT gateway (outbound internet acces)    

az network vnet subnet create \
        --resource-group ${rg} \
        --vnet-name ${pfx}-vnet \
        --name ${pfx}-deploy \
        --nat-gateway ${pfx}-natgw --address-prefixes ${deploy_cidr}

# Bastion subnet

az network vnet subnet create \
        --resource-group ${rg} \
        --vnet-name ${pfx}-vnet \
        --name AzureBastionSubnet \
        --address-prefixes ${bastion_cidr}

# public IP for the Bastion (we'll toss this later, but need to set it up)
# See https://docs.microsoft.com/en-us/azure/bastion/create-host-cli

az network public-ip create \
        --location ${loc} --resource-group ${rg} \
        --name ${pfx}-bastion-pubip \
        --sku standard \
        --allocation static

# does this need to be a new public-ip?
# get
# (PublicIpAddressInUse) PublicIPAddressInUse
# at end of create
# 
az network bastion create \
        --location ${loc} --resource-group ${rg} \
        --name ${pfx}-bastion --vnet ${pfx}-vnet \
        --public-ip-address ${pfx}-bastion-pubip

# user/pass
az vm create \
        --location ${loc} --resource-group ${rg} \
        --name ${pfx}-vm \
        --image UbuntuLTS \
        --public-ip-sku Standard \
        --size Standard_DS2_v2 \
        --admin-username ${vmadminuser} --admin-password ${vmadminpass}

# public sshkey VM variant
if (0); then
az vm create \
        --location ${loc} --resource-group ${rg} \
        --name ${pfx}-vm \
        --image UbuntuLTS \
        --public-ip-sku Standard \
        --size Standard_DS2_v2 \
        --admin-username ${vmadminuser} --ssh-key-values $sshkey
fi

# if you want internet-based ssh into the jumpbox, disable these commands ...
# this will leave a public ip into the jumpbox with ssh access.
# may want to move from password to public key access above

# if you do disable these (and allow publi internet ssh), you should probably replace the NSG rule with host specific access

# Should drop the NSG rule for ssh (even though bastion protected and we're about to drop the public IP)

az network nsg rule delete \
        --resource-group $rg \
        --nsg-name ${pfx}-vmNSG \
        --name default-allow-ssh

# dissociate, then delete
# note default naming of the ip-config as config${pfx}-vm (could explicitly name above)

az network nic ip-config update \
        --resource-group ${rg}  \
        --name ipconfig${pfx}-vm  \
        --nic-name ${pfx}-vmVMNic \
        --remove PublicIpAddress

az network nic delete \
        --resource-group ${rg}  \
        --name ${pfx}-vmVMNic
