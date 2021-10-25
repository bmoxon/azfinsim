#!/bin/bash -e
#
# Mass inject the trades.gz dataset 
#
source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "       (The redis cache needs to be created before you can inject the trade data)"
  exit 1
fi

ntr=1000000
if [ $# -eq 1 ]; then
  ntr=$1
fi

#-- get the redis password
AZFINSIM_REDIS_KEY=$(az keyvault secret show --name $AZFINSIM_REDIS_SECRET_ID \
	--vault-name $AZFINSIM_KV_NAME --query "value" | tr -d '",')

#-- inject 
echo "Injecting $ntr trades into cache $AZFINSIM_REDISHOST:6379"
time zcat ../data/trades.gz | head -n $ntr | redis-cli -h $AZFINSIM_REDISHOST -p 6379 -a $AZFINSIM_REDIS_KEY --pipe
