#!/bin/bash -e

# pull from ACR repo to local docker repo

source ./utils.sh
Config
if [ $? -ne 0 ]; then
	echo "       (azfinsim CONFIG ENV unavailablei)"
  exit 1
fi

az acr login -n $AZFINSIM_ACR

#-- And build the image directly in the container registry
IMAGEFQ="$AZFINSIM_ACR/$AZFINSIM_ACR_REPO/$AZFINSIM_ACR_SIM"

sudo docker pull $IMAGEFQ
