#!/bin/bash -e

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "       (The redis cache needs to be created before you can connect to it)"
  exit 1
fi

AZFINSIM_REDIS_KEY=$(az keyvault secret show --name $AZFINSIM_REDIS_SECRET_ID --vault-name $AZFINSIM_KV_NAME --query "value" | tr -d '",')

#-- redis-cli does not support SSL, ensure non-SSL port (default 6379) is open if you need to run this
#redis-cli -h $AZFINSIM_REDISHOST -p $AZFINSIM_REDISPORT -a "$AZFINSIM_REDIS_KEY"
redis-cli -h $AZFINSIM_REDISHOST -p 6379 -a "$AZFINSIM_REDIS_KEY"
