# utils.sh
# Set of utilities to be included in bash scripts via source

function Config {
  CONFIG="../config/azfinsim.config"
  if [ -f $CONFIG ]; then
    source $CONFIG
    return 0
  else
    echo "ERROR: Configuration file $CONFIG does not exist."
    echo "       You must first generate a configuration file by running ./deploy.sh"
    return 1
  fi
}
