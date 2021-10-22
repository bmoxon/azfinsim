# utils.sh
# should only be sourced

function Config {
    CONFIG="../config/azfinsim.config"
    if [ -f $CONFIG ]; then
        source $CONFIG
        return 0
    else 
        echo "ERROR: Configuration file $CONFIG does not exist. You must first generate a configuration file by running ./deploy.sh"
        echo "(The container registry needs to be created before you can build & push the container)"
        return 1
    fi
}
