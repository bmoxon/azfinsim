#!/bin/bash -e

#-- Deploy and additional run VM using the same PEM
#-- used to deploy additional runvms for dev work (likely different SKUs for experimentation)
#-- will create the VM and validate the container

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "(The container registry needs to be created before building and validating the container)"
  exit 1
fi

if [ $# -ne 2 ]; then
  echo "Usage: build-run.sh <vmname> <sku-name>"
  echo "  e.g. build-run.sh vmtest-e64 Standard_E64ds_v5"
  echo "       (note: uses same PEM/public key as headnode)"
  exit 1
fi

pemloc=~/.ssh/azfshn.pem
user=$AZFINSIM_HEADNODE_VM_ADMINUSER
host=$1
vmsku=$2
sshkey=$AZFINSIM_HEADNODE_VM_PUBKEY_ID

create_vm()
{
  vm=$(az vm list -g $AZURE_RG_NAME | jq -r '.[] | select(.name=="$host") | .name')
  if [ "$vm" == "$host" ]; then
    echo "$host already exists"
  else
    echo "Creating VM $host ..."
    az vm create \
          --location $AZURE_LOCATION --resource-group $AZURE_RG_NAME \
          --name $host \
          --image UbuntuLTS \
          --public-ip-sku Standard \
          --size ${vmsku} \
          --admin-username ${user} --ssh-key-values "$sshkey"
          
    # ToDo: really want dnsname in private dns

    hostip=$(az network public-ip show -n ${host}PublicIP -g $AZURE_RG_NAME | jq -r '.ipAddress')
    echo "$host publicip: ${hostip}"
  fi
}

prep_runnode()
{
   echo "Prepping runnode..."
   scp -o StrictHostKeyChecking=no -i ${pemloc} ${deploybin}/init-hn.sh  ${user}@${hostip}:~
   ssh -o StrictHostKeyChecking=no -i ${pemloc} ${user}@${hostip} chmod u+x ./init-hn.sh
   ssh -o StrictHostKeyChecking=no -i ${pemloc} ${user}@${hostip} ./init-hn.sh | tee ${deploybin}/../../logs/init-hn.log
   scp -o StrictHostKeyChecking=no -i ${pemloc} ${deploybin}/../../config/azfinsim.config ${user}@${hostip}:~/azfinsim-run/config/
}

echo_ssh_cmd()
{
   echo
   echo "To ssh to ${host}:"
   echo "$ ssh -i ~/.ssh/azfshn.pem ${user}@${hostip}"
}

deploybin=$(pwd)
create_vm
prep_runnode
echo_ssh_cmd
