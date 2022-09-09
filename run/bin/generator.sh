#!/bin/bash -e
#
# Generate the synthetic input trades serially
#
source ./utils.sh
Config
if [ $? -ne 0 ]; then
   echo "ERROR: Configuration file $CONFIG does not exist. You must first generate a configuration file by running ./deploy.sh"
   echo "(The redis cache needs to be created before you can inject the trade data)"
   exit 1
fi

ntr=1000000
if [ $# -eq 1 ]; then
  ntr=$1
fi

#-- get the redis password
AZFINSIM_REDIS_KEY=$(az keyvault secret show --name $AZFINSIM_REDIS_SECRET_ID --vault-name $AZFINSIM_KV_NAME --query "value" | tr -d '",')

echo "Generating (generator.py) $ntr trades into cache $AZFINSIM_REDISHOST:6379"
../src/generator.py \
	--start-trade 0 --trade-window $ntr \
	--cache-type redis --cache-name $AZFINSIM_REDISHOST --cache-port $AZFINSIM_REDISPORT --cache-ssl yes \
	--format eyxml --verbose false 
