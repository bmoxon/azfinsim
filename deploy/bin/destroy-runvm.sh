#!/bin/bash -e
#-- delete a runvm, including dependent resources (osdisk, nic, ip, nsg)

# ToDo: (bcm) should probably be rolled into terraform deployment, along with the VM creation

#echo "broken.  don't bother - go add the terraform stuff for a headnode and bastion"
#exit

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "(The container registry needs to be created before building and validating the container)"
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: destroy-runvm.sh <vmname>"
  exit
fi

host=$1

osDisk=$(az vm show -g $AZURE_RG_NAME --name ${host} --query "storageProfile.osDisk.id" --output tsv)
pubIp=$(az network public-ip show -g ${AZURE_RG_NAME} -n ${host}PublicIP --query "id" --output tsv)
Nic=$(az network nic show -g ${AZURE_RG_NAME} -n ${host}VMNic --query "id" --output tsv)
Nsg=$(az network nsg show -g ${AZURE_RG_NAME} -n ${host}NSG --query "id" --output tsv)

echo $osDisk
echo $pubIp
echo $Nic
echo $Nsg

# delete the vm
echo "deleting vm ${host}, then dependent resources. ^C to abort"
az vm delete -g ${AZURE_RG_NAME} -n ${host}

# os disk
az resource delete -g ${AZURE_RG_NAME} -n ${osdisk} --yes

az network nic ip-config update \
	--ids $Nic \
	--remove PublicIpAddress
  
# network resources - Nic, NSG, PublicIP
az resource delete --ids $pubIp
az resource delete --ids $Nic
az resource delete --ids $Nsg


