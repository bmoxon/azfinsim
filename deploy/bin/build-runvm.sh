#!/bin/bash -e
#-- Create a run VM; then go validate the container using run/bin tests

# ToDo: (bcm) should probably be rolled into terraform deployment

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "(The container registry needs to be created before building and validating the container)"
  exit 1
fi

if [ $# -ne 2 ]; then
  echo "Usage: build-run.sh <vmname> <vmadminuser>"
  echo "       (note: uses public key from the current shell, i.e. ~/.ssh/id_rsa.pub)"
  exit
fi

host=$1
vmadminuser=$2
sshkey="~/.ssh/id_rsa.pub"

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
        --size Standard_DS2_v2 \
        --admin-username ${vmadminuser} --ssh-key-values $sshkey
fi

# ToDo: really want dnsname in private dns

vmip=$(az network public-ip show -n ${host}PublicIP -g $AZURE_RG_NAME | jq -r '.ipAddress')
echo "$host publicip: ${vmip}"

# set up the run-vm

# sparse pull of the azfinsim run code
# push a copy of the generated azfinsim.config file

ssh-keygen -f ~/.ssh/known_hosts -R "${vmip}"
scp -o StrictHostKeyChecking=no init-runvm.sh ${vmadminuser}@${vmip}:~
ssh -o StrictHostKeyChecking=no ${vmadminuser}@${vmip} chmod u+x ./init-runvm.sh
ssh -o StrictHostKeyChecking=no ${vmadminuser}@${vmip} ./init-runvm.sh

echo "To ssh to the run-vm $host:"
echo "ssh ${vmadminuser}@${vmip}"

echo "for now, we'll leave this vm running for additional testing/dev, container updates, ..."
echo "if/when we want to get rid of it ..."
echo "az vm delete --name ${host} -g $AZURE_RG_NAME"

