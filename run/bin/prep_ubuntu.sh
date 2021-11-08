#!/bin/bash -xe

#-- helper script for environment prep on Ubuntu 18.04, 20.04, 20.10 ++>

sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

sudo apt-get install -y jq redis-tools
sudo apt-get install -y python3 python3-pip python3-venv

mkdir -p ~/pythonenvs
python3 -m venv ~/pythonenvs/azfsenv
. ~/pythonenvs/azfsenv/bin/activate
python3 -m pip install --upgrade pip
sudo cat > ~/.profile << EOF

# activate python env
source ~/pythonenvs/azfsenv/bin/activate
EOF

pip3 install -r ~/azfinsim-run/run/src/requirements.txt

