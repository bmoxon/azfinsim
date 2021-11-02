# azdeployenv

## Overview

Scripts to create and validate an azfinsim deployment environment in Azure.

Creates a small Ubuntu 18.04 VM, makes it available only via Bastion (for http proxy-constrained client environments).
Provides a validation script to check for required service and permission configuration.

The default config uses user/password authentication to the bastion-based VM (jumpbox), disables SSH and RDP access through the Bastion,
and removes the VM public IP address.

Once set up, the deployment VM should be configured (vmconfig.sh).
This will update the kernel, set up all needed prerequisites, and clone the repo to the deployment jumpbox.

This approach ensures a consistent deployment environment within the Azure networking environment.
It affords a full deployment of azfinsim (including docker container build/push), and (optionally) sets up private endpoints for each of
the services:
. Keyvault
. Container
. Redis cache
. Batch

This affords a fully private configuration that can deployed and executed in a sandboxed environment from a user's http proxy-protected desktop.

## Preparation

Install the current version of azcli on your workstation or use Azure shell for the initial setup of the deployment environment.

## Deployment script modifications

Edit the values of the variables at the top of deployenv.sh if needed.

```bash
./deployenv.sh
```

