#!/bin/bash

# set_starttask.sh
# push a new start task to blob store as AzFinSimStartTask.sh
# overwrite that instead of setting a new task, as we can't set run-elevated through the az batch pool set command in CLI
# see
# https://stackoverflow.com/questions/52981828/azure-batch-elevating-the-user-privileges-during-pool-creation-using-azure-cli
# Note we could supply a JSON, e.g. by pulling down the original startTask description and patching it.
# But just easier to push all start tasks up to object store as AzFinSimStartTask.sh and leave it at that

if [ $# -ne 1 ]; then
  echo "Usage: set_starttask.sh <local .sh filename (don't add ../src/)>"
  echo "  e.g. set_starttask.sh AzFinSimStartTaskFuse.sh"
  echo "       will upload specified file to AzFinSimStartTask.sh"
  exit 1
fi

# starttasks in ../src
starttaskdir=../src

newStartTask=$1
if [ ! -f $starttaskdir/$newStartTask ]; then
  echo "new start task file not found: $starttaskdir/$newStartTask - must be a bash script"
  exit 1
fi

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "(Deployment runtime config not created properly)"
  exit 1
fi

# Get the SAS KEY from the vault
AZFINSIM_STORAGE_SAS_TOKEN=$(az keyvault secret show --name $AZFINSIM_STORAGE_SAS_SECRET_ID --vault-name $AZFINSIM_KV_NAME --query "value" | tr -d '",')

# Upload the file

echo "uploading new starttask $newStartTask to blob as AzFinSimStartTask.sh"
az storage blob upload \
        --account-name $AZFINSIM_STORAGE_ACCOUNT \
        --sas-token "$AZFINSIM_STORAGE_SAS_TOKEN" \
        -c $AZFINSIM_STORAGE_CONTAINER_NAME \
        -f $starttaskdir/$newStartTask -n AzFinSimStartTask.sh
