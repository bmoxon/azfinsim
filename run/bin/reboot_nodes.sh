#!/bin/bash

# reboot_nodes.sh
# reboot active pool nodes, e.g. after setting a new StartTask

# should be better than resizing to 0, then back to N.

if [ $# -ne 2 ]; then
  echo "Usage: reboot_pool_nodes.sh <pool_id> <N>"
  echo "       Disable autoscale on the specified pool and manually scale to N nodes"
  exit 1
fi

poolId=$1
N=$2

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "(Deployment runtime config not created properly)"
  exit 1
fi

# batch login

az batch account login --resource-group $AZURE_RG_NAME --name $AZFINSIM_BATCH_ACCOUNT --show

# check the supplied poolid
dednodes=$(az batch pool show --pool-id $poolId | jq -r '.currentDedicatedNodes')
if [ "$dednodes" == "" ]; then
  echo "az batch pool $poolId not found"
  exit 1
fi

# az batch pool node-counts list
ni=$(az batch pool node-counts list --query "[?poolId=='"$poolId"'].{Idle:dedicated.idle}" | jq -r ".[].Idle")
echo "Reconfiguring $ni nodes in pool $poolId"

# disable autoscale
echo "Disabling autoscale ..."
az batch pool autoscale disable --pool-id $poolId

# manually resize
echo "Manually resizing to $N nodes"
az batch pool resize --pool-id $poolId --target-dedicated-nodes $N

echo "Waiting for $N nodes in idle state ..."

ni=0
while [ $ni -ne $N ]; do
  ni=$(az batch pool node-counts list --query "[?poolId=='"$poolId"'].{Idle:dedicated.idle}" | jq -r ".[].Idle")
  echo "Idle nodes in $poolId: $ni"
  sleep 10
done
