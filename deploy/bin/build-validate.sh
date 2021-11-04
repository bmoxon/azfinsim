#!/bin/bash -e
#-- Validate the container we built and pushed via az acr build

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "(The container registry needs to be created before building and validating the container)"
  exit 1
fi

#-- fire up a vm to test ...
host="container-test-vm"
vmadminuser="azureuser"
sshkey="~/.ssh/id_rsa.pub"

vm=$(az vm list -g bcmazfsrg | jq -r '.[] | select(.name=="container-test-vm") | .name')
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
#--assign-identity
fi

#prinid=$(az vm show -g $AZURE_RG_NAME -n $host --query "identity.principalId" -otsv)
#az role assignment create --assignee ${prinid} --role contributor -g $AZURE_RG_NAME > /dev/null

vmip=$(az network public-ip show -n container-test-vmPublicIP -g bcmazfsrg | jq -r '.ipAddress')
echo "$host publicip: ${vmip}"

#-- quick test on the local build host to ensure container is functional

echo "Creaating container validation script cvalid-script.sh to run remotely on $host"

cat > cvalid-script.sh <<EOF
#!/bin/bash -e
#-- container validation script for remote execution on $host (${vmip})

source ../config/azfinsim.config

#-- install az cli
which az
if [ \$? -ne 0 ]; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

#-- docker install if needed
which docker
if [ \$? -ne 0 ]; then
  sudo apt-get install -y docker.io
  sudo usermod -aG docker \$(whoami)
  newgrp docker
fi

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET \
	--tenant $AZURE_TENANT_ID

#-- Pull the keys we need from keyvault
AZFINSIM_ACR_KEY=\$(az keyvault secret show --name \$AZFINSIM_ACR_SECRET_ID \
	--vault-name \$AZFINSIM_KV_NAME --query "value" | tr -d '",')

#-- Pull the container and run locally
docker login \$AZFINSIM_ACR -u \$AZFINSIM_ACR_USER -p \$AZFINSIM_ACR_KEY
IMAGEFQ="\$AZFINSIM_ACR/\$AZFINSIM_ACR_REPO/\$AZFINSIM_ACR_SIM"

#sudo docker pull \$IMAGEFQ

sudo docker run bcmazfsazcr.azurecr.io/azfinsim/azfinsimub1804 ls -al /azfinsim/
sudo docker run bcmazfsazcr.azurecr.io/azfinsim/azfinsimub1804 /azfinsim/azfinsim.py --help

EOF

# probably just need to refactor repo and do a sparse git pull (run vs. deploy)
# and run prep_ubuntu.sh there

#-- copy over the config and cvalid-script.sh
ssh -o StrictHostKeyChecking=no -l ${vmadminuser} ${vmip} mkdir -p config
ssh -o StrictHostKeyChecking=no -l ${vmadminuser} ${vmip} mkdir -p bin
scp ../config/azfinsim.config azureuser@${vmip}:~/config
scp cvalid-script.sh azureuser@${vmip}:~/bin
ssh -o StrictHostKeyChecking=no -l ${vmadminuser} ${vmip} chmod u+x bin/cvalid-script.sh

#-- apend to remote .bash_profile
echo "source pythonenvs/azfinsim/bin/activate" | ssh -o StrictHostKeyChecking=no -l ${vmadminuser} ${vmip} "cat >> .bash_profile"
echo "source config/azfinsim.config" | ssh -o StrictHostKeyChecking=no -l ${vmadminuser} ${vmip} "cat >> .bash_profile"

echo "for now, we'll leave this vm running for additional testing/dev, container updates, ..."
echo "if/when we want to get rid of it ..."
echo "az vm delete --name container-test-vm -g $AZURE_RG_NAME"
