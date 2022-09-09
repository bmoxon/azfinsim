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
  echo "  e.g. destroy-runvm.sh vmtest-e64v3"
  exit 1
fi

host=$1

show_vm()
{
  vm_id=$(az vm show --resource-group $AZURE_RG_NAME --name $host | jq -r '.id')
  if [ $? -ne 0 ]; then
    echo "VM $host not found. Exiting."
    exit 1
  fi

  osdisk_id=$(az vm show --resource-group $AZURE_RG_NAME --name $host | jq -r '.storageProfile.osDisk.name')
  nic_id=$(az network nic show --resource-group $AZURE_RG_NAME --name ${host}VMNic | jq -r '.id')
  pubip_id=$(az network public-ip show --resource-group $AZURE_RG_NAME --name ${host}PublicIp | jq -r '.id')
  nsg_id=$(az network nsg show --resource-group $AZURE_RG_NAME --name ${host}NSG | jq -r '.id')

  echo "vm_id     : $vm_id"
  echo "osdisk_id : $osdisk_id"
  echo "nic_id    : $nic_id"
  echo "pubip_id  : $pubip_id"
  echo "nsg_id    : $nsg_id"
}

destroy_vm()
{
  # disassociate publicip from nic
  az network nic ip-config update --resource-group $AZURE_RG_NAME --name ipconfig${host} --nic-name ${host}VMNic --remove PublicIpAddress

if [ $? -ne 0 ]; then
    echo "error dissociating publicip from nic on $host; check portal"
  fi

  # delete the vm
  az vm delete --ids $vm_id --yes
  if [ $? -ne 0 ]; then
    echo "error deleting the VM $vm_id; check portal"
  fi

  # and delete the osdisk, nic, and nsg

  az disk delete --ids $nic_id --yes
  if [ $? -ne 0 ]; then
    echo "error deleting the NIC $nic_id; check portal"
  fi

  az network nic delete --ids $nic_id
  if [ $? -ne 0 ]; then
    echo "error deleting the NIC $nic_id; check portal"
  fi

  az network public-ip delete --ids $pubip_id
  if [ $? -ne 0 ]; then
    echo "error deleting the public ip $pubip_id; check portal"
  fi

  az network nsg delete --ids $nsg_id
  if [ $? -ne 0 ]; then
    echo "error deleting the NSG $nsg_id; check portal"
  fi

}

deploybin=$(pwd)
show_vm
read -p "Are you sure you want to destroy this VM (YES/)?" RESP
if [ "$RESP" != "YES" ]; then
  echo "Requires a YES to confirm; quitting."
  exit
fi

destroy_vm
