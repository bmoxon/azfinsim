#!/bin/bash -e
#-- Build & test the docker image locally before running on the grid

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
pushd ../src
az acr build --image $IMAGEFQ --registry $AZFINSIM_ACR --file Dockerfile.azfinsim .
popd

#-- Verify its existence

echo "Querying the repo for container $AZFINSIM_ACR_REPO/$AZFINSIM_ACR_SIM ..."
az acr repository show -n $AZFINSIM_ACR --repository azfinsim/azfinsimub1804

echo "Running the container ..."

az acr run --registry $AZFINSIM_ACR --cmd '$Registry/azfinsim/azfinsimub1804 ls -la /azfinsim/' /dev/null

az acr run --registry $AZFINSIM_ACR --cmd '$Registry/azfinsim/azfinsimub1804 /azfinsim/azfinsim.py --help' /dev/null

echo "test completed."
