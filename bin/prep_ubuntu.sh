#!/bin/bash -xe

#-- helper script for environment prep on Ubuntu 18.04, 20.04, 20.10 ++>

#sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

apt-get install -y jq redis-tools
python3 -m pip install --upgrade pip

mkdir -p ~/pythonenvs
python3 -m venv ~/pythonenvs/azfsenv
~/pythonenvs/azfinsim/bin/activate
pip3 install -r ../src/requirements.txt
