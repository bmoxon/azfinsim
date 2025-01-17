#!/bin/bash -e
#
# submit batch job
#

source ./utils.sh
Config
if [ $? -ne 0 ]; then
  echo "(The batch pool, container registry & redis cache need to be created before you can run a job)"
  exit 1
fi

AZFINSIM_REDIS_KEY=$(az keyvault secret show --name $AZFINSIM_REDIS_SECRET_ID --vault-name $AZFINSIM_KV_NAME --query "value" | tr -d '",')

#-- select pool 
POOL=$AZFINSIM_AUTOSCALE_POOL
#POOL=$AZFINSIM_REALTIME_POOL

#-- trades to process (pull count from redis)
TRADES=$(redis-cli -h $AZFINSIM_REDISHOST -p 6379 -a "$AZFINSIM_REDIS_KEY" KEYS "ey*.xml" | wc -l)
echo $TRADES "TRADES"

TRADES_PER_TASK=10
echo $TRADES_PER_TASK TRADES_PER_TASK

#-- tasks (TRADES/TASKS = number of trades to run per task/core, so 1000000/10000 = 100 trades per task running on each core) 
TASKS=$(( TRADES / TRADES_PER_TASK ))
echo $TASKS "TASKS"

# SYNTHETIC run - 50 milliseconds per trade
../src/submit.py --job-id "Sythetic50ms" --pool-id $POOL \
	--start-trade 0 --trade-window $TRADES \
	--tasks $TASKS --threads 10 \
	--cache-type redis --cache-name $AZFINSIM_REDISHOST --cache-port $AZFINSIM_REDISPORT --cache-ssl yes \
	--format eyxml --algorithm synthetic --task-duration 50 --mem-usage 16 --failure 0.0

# Run via the Harvester "Scheduler"
#../src/submit.py --harvester true --start-trade 0 --trade-window 1000 --tasks 25 --threads 100 --task-duration 50 --cache-type redis --cache-name $REDISHOST --cache-port $REDISPORT --cache-ssl yes --format eyxml --algorithm pvonly --failure 0.0
