#!/usr/bin/env python3

import azure.batch._batch_service_client as batch
import azure.batch.batch_auth as batchauth
import azure.batch.models as batchmodels
from azure.batch import BatchServiceClient
from azure.common.credentials import ServicePrincipalCredentials
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

from getargs import getargs
from config import *
import config
import secrets
import azlog

if __name__ == '__main__':

  #-- grab cli args
  #args = getargs("batchimglist")

  #-- pull keys/passwords from the keyvault
  secrets.ReadKVSecrets()

  credentials = secrets.SetupAADAuth()
  client = batch.BatchServiceClient(credentials, batch_url=AZFINSIM_ENDPOINT)

  # Get the list of supported images from the Batch service
  images = client.account.list_supported_images()

  # Obtain the desired image reference
  image = None
  for img in images:
    print("{}, {}, {}".format(img.image_reference.publisher.lower(),
                              img.image_reference.offer.lower(),
                              img.image_reference.sku.lower()))
    if (img.image_reference.publisher.lower() == "canonical" and
          img.image_reference.offer.lower() == "ubuntuserver" and
          img.image_reference.sku.lower() == "18.04-lts"):
      image = img
      break

  if image is None:
    raise RuntimeError('invalid image reference for desired configuration')

  # Create the VirtualMachineConfiguration, specifying the VM image
  # reference and the Batch node agent to be installed on the node
  vmc = batchmodels.VirtualMachineConfiguration(
      image_reference=image.image_reference,
      node_agent_sku_id=image.node_agent_sku_id)

