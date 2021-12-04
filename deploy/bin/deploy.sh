#!/bin/bash -e

CONFIGDIR="../../config"
CONFIG=$CONFIGDIR/azfinsim.config

deploy()
{
    autoapprove=$1
    echo "Starting Terraform..."
    terraform init
    terraform plan -parallelism=30 

    if [ "$autoapprove" = true  ]; then
       terraform apply -auto-approve -parallelism=30
    else 
       terraform apply -parallelism=30
    fi 
}

generate_config()
{
    echo "Generating configuration..."
    vars=$(terraform output -json)

    if [ ! -d $CONFIGDIR ]; then
       mkdir -p $CONFIGDIR
    fi
    #-- location and resource group name
    AZURE_LOCATION=$(echo $vars | jq -r '.location.value')
    AZURE_RG_NAME=$(echo $vars | jq -r '.resource_group_name.value')

    #-- keyvault & stored secret identifiers
    AZFINSIM_KV_NAME=$(echo $vars | jq -r '.keyvault_name.value')
    AZFINSIM_KV_URL=$(echo $vars | jq -r '.keyvault_uri.value')
    AZFINSIM_ACR_SECRET_ID=$(echo $vars | jq -r '.acr_secret_name.value')
    AZFINSIM_REDIS_SECRET_ID=$(echo $vars | jq -r '.redis_secret_name.value')
    AZFINSIM_APPINSIGHTS_SECRET_ID=$(echo $vars | jq -r '.appinsights_secret_name.value')
    AZFINSIM_STORAGE_SAS_SECRET_ID=$(echo $vars | jq -r '.storage_sas_secret_name.value')
    AZFINSIM_APPDATA_STORAGE_SAS_SECRET_ID=$(echo $vars | jq -r '.appdata_storage_sas_secret_name.value')
    AZFINSIM_XNFS_STORAGE_SAS_SECRET_ID=$(echo $vars | jq -r '.xnfs_storage_sas_secret_name.value')
    AZFINSIM_HEADNODE_VM_PRIVKEY_ID=$(echo $vars | jq -r '.headnode_vm_ssh_private_key.value')
    AZFINSIM_HEADNODE_VM_PUBKEY_ID=$(echo $vars | jq -r '.headnode_vm_ssh_public_key.value')

    #-- secret is masked - pull from tfstate
    AZURE_CLIENT_SECRET=$(terraform show --json | jq -r '.values.outputs.sp_password.value')

    #-- non-sensitive terraform output variables
    AZURE_TENANT_ID=$(echo $vars | jq -r '.tenant_id.value')
    AZFINSIM_PRINCIPAL=$(echo $vars | jq -r '.sp_name.value')
    AZURE_CLIENT_ID=$(echo $vars | jq -r '.application_id.value')
    AZFINSIM_AUTOSCALE_POOL=$(echo $vars | jq -r '.autoscale_pool_name.value')
    AZFINSIM_REALTIME_POOL=$(echo $vars | jq -r '.realtimestatic_pool_name.value')
    AZFINSIM_BATCH_ACCOUNT=$(echo $vars | jq -r '.batch_account_name.value')
    batch_account_endpoint=$(echo $vars | jq -r '.batch_account_endpoint.value')
    AZFINSIM_ENDPOINT="https://$batch_account_endpoint"

    REDISHOST=$(echo $vars | jq -r '.redis_hostname.value')
    REDISPORT=$(echo $vars | jq -r '.redis_ssl_port.value')

    storage_account=$(echo $vars | jq -r '.primary_blob_endpoint.value')
    container_name=$(echo $vars | jq -r '.container_name.value')
    AZFINSIM_STORAGE_ACCOUNT=$(echo $vars | jq -r '.storage_account_name.value')
    AZFINSIM_STORAGE_CONTAINER_NAME="${container_name}"
    AZFINSIM_STORAGE_CONTAINER_URI="${storage_account}${container_name}"

    appdata_container_name=$(echo $vars | jq -r '.appdata_container_name.value')
    AZFINSIM_APPDATA_STORAGE_CONTAINER_NAME="${appdata_container_name}"
    AZFINSIM_APPDATA_STORAGE_CONTAINER_URI="${storage_account}${appdata_container_name}"

    xnfs_storage_account=$(echo $vars | jq -r '.xnfs_primary_blob_endpoint.value')
    xnfs_container_name=$(echo $vars | jq -r '.xnfs_container_name.value')
    AZFINSIM_XNFS_STORAGE_ACCOUNT=$(echo $vars | jq -r '.xnfs_storage_account_name.value')
    AZFINSIM_XNFS_STORAGE_CONTAINER_URI="$xnfs_storage_account$xnfs_container_name"

    APP_INSIGHTS_APP_ID=$(echo $vars | jq -r '.appinsights_app_id.value')

    AZFINSIM_ACR=$(echo $vars | jq -r '.azcr_server.value')
    AZFINSIM_ACR_USER=$(echo $vars | jq -r '.azcr_username.value')
    AZFINSIM_ACR_SIM="azfinsimub1804"
    AZFINSIM_ACR_REPO="azfinsim"
    AZFINSIM_ACR_IMAGE="$AZFINSIM_ACR/$AZFINSIM_ACR_REPO/$AZFINSIM_ACR_SIM"

    AZFINSIM_HEADNODE_VM_PUBIP=$(echo $vars | jq -r '.headnode_vm_pubip.value')
    #-- pem is masked - pull from tfstate
    AZFINSIM_HEADNODE_VM_PEM=$(terraform show --json | jq -r '.values.outputs.headnode_vm_ssh_private_key.value')
    AZFINSIM_HEADNODE_VM_ADMINUSER=$(echo $vars | jq -r '.headnode_vm_admin_user.value')
   
    #-- build environment file for user job submission scripts
cat << EOF > $CONFIG
#######################################
# Autogenerated by azfinsim deploy.sh #
#######################################
#-- azure rg and location
export AZURE_LOCATION="$AZURE_LOCATION"
export AZURE_RG_NAME="$AZURE_RG_NAME"
#-- batch service principal details
export AZURE_CLIENT_ID="$AZURE_CLIENT_ID"
export AZURE_CLIENT_SECRET="$AZURE_CLIENT_SECRET"
export AZURE_TENANT_ID="$AZURE_TENANT_ID"
export AZFINSIM_PRINCIPAL="$AZFINSIM_PRINCIPAL"
#-- azure batch account details
export AZFINSIM_BATCH_ACCOUNT="$AZFINSIM_BATCH_ACCOUNT"
export AZFINSIM_ENDPOINT="$AZFINSIM_ENDPOINT"
export AZFINSIM_AUTOSCALE_POOL="$AZFINSIM_AUTOSCALE_POOL"
export AZFINSIM_REALTIME_POOL="$AZFINSIM_REALTIME_POOL"
#-- keyvault details
export AZFINSIM_KV_NAME="$AZFINSIM_KV_NAME"
export AZFINSIM_KV_URL="$AZFINSIM_KV_URL"
export AZFINSIM_STORAGE_SAS_SECRET_ID="$AZFINSIM_STORAGE_SAS_SECRET_ID"
export AZFINSIM_ACR_SECRET_ID="$AZFINSIM_ACR_SECRET_ID"
export AZFINSIM_REDIS_SECRET_ID="$AZFINSIM_REDIS_SECRET_ID"
export AZFINSIM_APPINSIGHTS_SECRET_ID="$AZFINSIM_APPINSIGHTS_SECRET_ID"
export AZFINSIM_HEADNODE_VM_PUBKEY_ID="$AZFINSIM_HEADNODE_VM_PUBKEY_ID"
#-- storage 
export AZFINSIM_STORAGE_CONTAINER_URI="$AZFINSIM_STORAGE_CONTAINER_URI"
export AZFINSIM_STORAGE_CONTAINER_NAME="$AZFINSIM_STORAGE_CONTAINER_NAME"
export AZFINSIM_STORAGE_ACCOUNT="$AZFINSIM_STORAGE_ACCOUNT"
export AZFINSIM_APPDATA_STORAGE_CONTAINER_URI="$AZFINSIM_APPDATA_STORAGE_CONTAINER_URI"
export AZFINSIM_APPDATA_STORAGE_CONTAINER_NAME="$AZFINSIM_APPDATA_STORAGE_CONTAINER_NAME"

export AZFINSIM_XNFS_STORAGE_CONTAINER_NAME="$AZFINSIM_XNFS_STORAGE_CONTAINER_NAME"
export AZFINSIM_XNFS_STORAGE_CONTAINER_URI="$AZFINSIM_XNFS_STORAGE_CONTAINER_URI"
export AZFINSIM_XNFS_STORAGE_ACCOUNT="$AZFINSIM_XNFS_STORAGE_ACCOUNT"
#-- redis details
export AZFINSIM_REDISPORT=$REDISPORT
export AZFINSIM_REDISHOST="$REDISHOST"
export AZFINSIM_REDISSSL="yes"
#-- application insights
export APP_INSIGHTS_APP_ID="$APP_INSIGHTS_APP_ID"
#-- container registry details 
export AZFINSIM_ACR="$AZFINSIM_ACR"
export AZFINSIM_ACR_REPO="azfinsim"
export AZFINSIM_ACR_USER="$AZFINSIM_ACR_USER"
export AZFINSIM_ACR_SIM="azfinsimub1804"
export AZFINSIM_ACR_IMAGE="$AZFINSIM_ACR_IMAGE"
#-- headnode
export AZFINSIM_HEADNODE_VM_ADMINUSER="$AZFINSIM_HEADNODE_VM_ADMINUSER"
export AZFINSIM_HEADNODE_VM_PUBIP="$AZFINSIM_HEADNODE_VM_PUBIP"
EOF
} 

check_env()
{ 
    for cmd in terraform jq az; do 
       if ! command -v $cmd  &> /dev/null
       then
          echo "ERROR: command $cmd could not be found"
          echo "azfinsim requires terraform, jq & azure cli to be installed." 
          exit 1
       fi
    done 
} 

usage()
{
    echo -e "\nUsage: $(basename $0) [-auto-approve <auto approve terraform apply (default = prompt for approval)>]"
    exit 1
} 

pemloc=~/.ssh/azfshn.pem
user=$AZFINSIM_HEADNODE_VM_ADMINUSER

get_headnode_pem()
{
   echo "Writing new headnode pem to ${pemloc}"
   if [ -f ${pemloc} ]; then
     ts=$(date +%Y%m%dT%H%M%S)
     echo "Found existing azfshn.pem; moving to azfsnh.pem.backup.${ts}"
     mv $pemloc $pemloc.backup.${ts}
   fi
   #printf "%s" $AZFINSIM_HEADNODE_VM_PEM > $pemloc
   echo "$AZFINSIM_HEADNODE_VM_PEM" > ${pemloc}
   chmod 400 ${pemloc}
}

prep_headnode()
{
   echo "Prepping headnode..."
   user=$AZFINSIM_HEADNODE_VM_ADMINUSER
   host=$AZFINSIM_HEADNODE_VM_PUBIP
   scp -o StrictHostKeyChecking=no -i ${pemloc} ${deploybin}/init-hn.sh  ${user}@${host}:~
   ssh -o StrictHostKeyChecking=no -i ${pemloc} ${user}@${host} chmod u+x ./init-hn.sh
   ssh -o StrictHostKeyChecking=no -i ${pemloc} ${user}@${host} ./init-hn.sh | tee ${deploybin}/../../logs/init-hn.log
   scp -o StrictHostKeyChecking=no -i ${pemloc} ${deploybin}/../../config/azfinsim.config ${user}@${host}:~/azfinsim-run/config/
}

echo_ssh_cmd()
{
   echo
   echo "To ssh to the headnode:"
   echo "$ ssh -i ~/.ssh/azfshn.pem azfinsim@$AZFINSIM_HEADNODE_VM_PUBIP"
}

autoapprove=false
while [[ $# -gt 0 ]]
do
   key="$1"
   case $key in
      -auto-approve)
         autoapprove=true
         shift;
      ;;
      *)
         usage
         shift;
      ;;
   esac
done

check_env
deploybin=$(pwd)
pushd ../terraform >/dev/null 
deploy $autoapprove
generate_config
get_headnode_pem
prep_headnode
echo_ssh_cmd
popd >/dev/null 
