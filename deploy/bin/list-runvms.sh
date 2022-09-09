#!/bin/bash

# list runvms

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "The deployment config does not exist."
  exit 1
fi

az vm list --resource-group $AZURE_RG_NAME | jq -r '.[].name'
