#!/bin/bash -xe

#-- helper script for environment prep on Ubuntu 18.04, 20.04, 20.10 ++>

sudo apt update

#sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

sudo apt install -y jq redis-tools
sudo apt install -y python3 python3-pip python3-venv
python3 -m pip install --upgrade pip

mkdir -p ~/pythonenvs
python3 -m venv ~/pythonenvs/azfsenv
. ~/pythonenvs/azfsenv/bin/activate
sudo -H pip3 install -r ~/azfinsim-run/run/src/requirements.txt

