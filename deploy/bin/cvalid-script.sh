#!/bin/bash -e
#-- container validation script for remote execution on container-test-vm (20.99.159.79)

source ../config/azfinsim.config

#-- install az cli
which az
if [ $? -ne 0 ]; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

#-- docker install if needed
which docker
if [ $? -ne 0 ]; then
  sudo apt-get install -y docker.io
  sudo usermod -aG docker $(whoami)
  newgrp docker
fi

az login --service-principal -u 81298e5f-d647-4647-bd4c-17404b22f3d8 -p TFdDK!N%Cl950Gpor2VE_s/WxmbiBtO36S 	--tenant 72f988bf-86f1-41af-91ab-2d7cd011db47

#-- Pull the keys we need from keyvault
AZFINSIM_ACR_KEY=$(az keyvault secret show --name $AZFINSIM_ACR_SECRET_ID 	--vault-name $AZFINSIM_KV_NAME --query "value" | tr -d '",')

#-- Pull the container and run locally
docker login $AZFINSIM_ACR -u $AZFINSIM_ACR_USER -p $AZFINSIM_ACR_KEY
IMAGEFQ="$AZFINSIM_ACR/$AZFINSIM_ACR_REPO/$AZFINSIM_ACR_SIM"

#sudo docker pull $IMAGEFQ

sudo docker run bcmazfsazcr.azurecr.io/azfinsim/azfinsimub1804 ls -al /azfinsim/
sudo docker run bcmazfsazcr.azurecr.io/azfinsim/azfinsimub1804 /azfinsim/azfinsim.py --help

