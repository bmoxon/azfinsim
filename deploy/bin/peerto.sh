#!/bin/bash

# peerto.sh
# set up vnet peering between azfinsim vnet and hub vnet/vpn

if [ $# -ne 2 ]; then
  echo "Usage: peerto.sh <hub rg> <hub vnet>"
  exit
fi

hubrg=$1
hubvnet=$2

azfsrg="bcmazfscsrg"
azfsvnet="bcmazfscs-vnet"

azfsvnetid=$(az network vnet show --resource-group ${azfsrg} --name ${azfsvnet} --query id --out tsv)
hubvnetid=$(az network vnet show --resource-group ${hubrg} --name ${hubvnet} --query id --out tsv)

echo "peering ..."
echo $azfsvnetid
echo "...and..."
echo $hubvnetid

# delete the old azfs peer in westus2hub if needed
az network vnet peering delete --name azfs-to-westus2hub --resource-group ${azfsrg} --vnet-name ${azfsvnet}

az network vnet peering create --name westus2hub-to-azfs --resource-group ${hubrg} --vnet-name ${hubvnet} --remote-vnet ${azfsvnetid} --allow-vnet-access
az network vnet peering create --name azfs-to-westus2hub --resource-group ${azfsrg} --vnet-name ${azfsvnet} --remote-vnet ${hubvnetid} --allow-vnet-access

