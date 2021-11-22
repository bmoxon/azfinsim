#!/bin/bash -e
#-- Show current ACR image info

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "(The container registry needs to be created before you can build & push the container)"
  exit 1
fi

#-- Pull the keys we need from keyvault
AZFINSIM_ACR_KEY=$(az keyvault secret show --name $AZFINSIM_ACR_SECRET_ID --vault-name $AZFINSIM_KV_NAME --query "value" | tr -d '",') 

#-- And build the image directly in the container registry
IMAGEFQ="$AZFINSIM_ACR/$AZFINSIM_ACR_REPO/$AZFINSIM_ACR_SIM"

#-- Verify its existence

echo "Querying the repo for container $AZFINSIM_ACR_REPO/$AZFINSIM_ACR_SIM ..."
az acr repository show -n $AZFINSIM_ACR --repository $AZFINSIM_ACR_REPO/$AZFINSIM_ACR_SIM
