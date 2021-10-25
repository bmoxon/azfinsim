#!/bin/bash -e
#-- Build & test the docker image locally before running on the grid
source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "(The container registry needs to be created before you can build & push the container)"
  exit 1
fi

#-- Pull the keys we need from keyvault
AZFINSIM_ACR_KEY=$(az keyvault secret show --name $AZFINSIM_ACR_SECRET_ID \
	--vault-name $AZFINSIM_KV_NAME --query "value" | tr -d '",') 

#-- Build azfinsim docker container and push to the azure container registry 
sudo docker login $AZFINSIM_ACR -u $AZFINSIM_ACR_USER -p $AZFINSIM_ACR_KEY
IMAGEFQ="$AZFINSIM_ACR/$AZFINSIM_ACR_REPO/$AZFINSIM_ACR_SIM"
pushd ../src
sudo docker build . -f Dockerfile.azfinsim --no-cache --rm --tag $IMAGEFQ
sudo docker push $IMAGEFQ

#-- quick test on the local build host to ensure container is functional
sudo docker run $IMAGEFQ ls -la /azfinsim/
sudo docker run $IMAGEFQ /azfinsim/azfinsim.py --help
popd
echo "test completed."
