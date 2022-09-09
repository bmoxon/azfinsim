#!/bin/bash -e
#
# Dump the database to a file dump.txt
#

source ./utils.sh
Config
if [ $? -ne 0 ]; then
   echo "ERROR: Configuration file $CONFIG does not exist. You must first generate a configuration file by running ./deploy.sh"
   exit 1
fi

AZFINSIM_REDIS_KEY=$(az keyvault secret show --name $AZFINSIM_REDIS_SECRET_ID --vault-name $AZFINSIM_KV_NAME --query "value" | tr -d '",')

# nkeys

ntrades=$(redis-cli -h $AZFINSIM_REDISHOST -p 6379 -a "$AZFINSIM_REDIS_KEY" keys 'ey*'| wc -l)
if [ $ntrades -eq 1 ]; then
  trades=$(redis-cli -h $AZFINSIM_REDISHOST -p 6379 -a "$AZFINSIM_REDIS_KEY" keys 'ey*')
  if [ "$trades" == "" ]; then
    echo "no trades in redis; exiting"
    exit 1
  fi
fi

echo "dumping $ntrades trades to dump.txt"

../src/dump.py \
	--start-trade 0 --trade-window $ntrades \
	--cache-type redis --cache-name $AZFINSIM_REDISHOST --cache-port $AZFINSIM_REDISPORT --cache-ssl yes \
	--format eyxml --verbose false 
