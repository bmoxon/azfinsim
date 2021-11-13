#!/bin/bash -e

# init-hn.sh
# init the environment for the headnode

# installing az cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# installing terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository \
	"deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install -y terraform

sudo apt install -y docker.io
sudo usermod -aG docker $(whoami)

echo "pulling azfinsim/run from github"

mkdir -p azfinsim-run
pushd azfinsim-run
git init
git config core.sparsecheckout true
echo config/ > .git/info/sparse-checkout
echo run/bin/ >> .git/info/sparse-checkout
echo run/src/ >> .git/info/sparse-checkout
echo run/data/ >> .git/info/sparse-checkout
echo run/img/ >> .git/info/sparse-checkout
rem=$(git remote)
if [ "$rem" != "origin" ]; then
  git remote add -f origin https://github.com/bmoxon/azfinsim.git
fi
git pull origin cloudshell-noep
popd

echo "prepping the runvm (ubuntu)"
./azfinsim-run/run/bin/prep_ubuntu.sh

if [ -f ~/.bash_profile ]; then
  echo ".bash_profile exists; not overwriting"
else
  echo "Creating .bash_profile"
  sudo cat > ~/.bash_profile << EOF
# activate python env
source ~/pythonenvs/azfsenv/bin/activate

# az login
. \$HOME/azfinsim-run/config/azfinsim.config
az login --service-principal -u '$AZURE_CLIENT_ID' -p '$AZURE_CLIENT_SECRET' --tenant '$AZURE_TENANT_ID'

# redis env vars
export AZFINSIM_REDIS_KEY="$(az keyvault secret show \
        --name $AZFINSIM_REDIS_SECRET_ID --vault-name $AZFINSIM_KV_NAME --query "value" \
        | tr -d '",')"

# setup rcli alias
alias rcli='redis-cli -h \$AZFINSIM_REDISHOST -p 6379 -a \$AZFINSIM_REDIS_KEY'

EOF
fi


