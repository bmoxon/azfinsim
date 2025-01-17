#!/bin/bash -xe
echo "AzFinSimStartTaskFuse.sh"

/bin/bash -c 'wget  -O - https://raw.githubusercontent.com/Azure/batch-insights/master/scripts/run-linux.sh | bash'

# Task startup run under _azbatch user

# I would have though blob fuse was already installed, but maybe not
# if not, may have to ... (though i think this will have the same dialog issue?)
# https://github.com/moby/moby/issues/27988
# also have to deal with dpkg lock issues requiring multiple attempts?

# cant write to stdout ??
#/bin/bash -c 'wget -O - https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb | sudo dpkg -i'
wget "https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb

sudo apt-get -y -q update
sudo apt-get install -y -q dialog apt-utils
sudo apt-get -y -q install blobfuse

# set up local cache dir (just setting up blob fuse for the batch-explorer-user)

sudo mkdir -p /mnt/resource/blobfusetmp
me=$(whoami)
sudo chown $me /mnt/resource/blobfusetmp

# How to set these in the .sh as part of deploy (?)
# try template fillin at tail end of deploy?
# but seems like this is stuck in the object store during batch resource creation (?)
# so may have to patch it and azcopy it over after deploy ...

# for now, just hardcode the ENV vars for current test scenario

cat > ./appdata_blobfuse.cfg <<END
accountName bcmazfsstorage
authType SAS
sasToken ?sv=2018-11-09&sr=c&st=2021-01-01&se=2025-01-01&sp=racwdl&spr=https&sig=fyZPllkYhyJtan%2FKNo7Jk6FgntpL4o3kLSgRmymDVHw%3D"
containerName azfinsim
END

# make the mount directory and do the mount
# note for now this just mounts the same directory accessible through
# /mnt/batch/tasks/startup/wd
# but this sets the stage for an alternative storage account just for the data, not the batch runtime stuff

mkdir -p /mnt/batch/tasks/fsmounts/azfinsim-data
sudo chown _azbatch:_azbatchgrp /mnt/batch/tasks/fsmounts/azfinsim-data
sudo blobfuse /mnt/batch/tasks/fsmounts/azfinsim-data --tmp-path=/mnt/resource/blobfusetmp \
    -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 \
    --config-file=./appdata_blobfuse.cfg
