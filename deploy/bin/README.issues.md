Current issues ...

(1) appinsights not initialized properly (api getting response "")
fixed by importing the app-insights that are properly created
(this appears to be either a timing/dependency issue or a re-apply issue)

terraform import azurerm_application_insights.azfinsim <id from error message>
e.g.
terraform import azurerm_application_insights.azfinsim /subscriptions/f5a67d06-2d09-4090-91cc-e3298907a021/resourceGroups/bcmazfsrg/providers/microsoft.insights/components/bcmazfs-appinsights

(2) MSFT internal security installs NSG rules preventing the prep_headnode (usually) - time for NRMS rules seems variable

So ...
(a) Set up a vnet peer between my dev env and the newly created azfs vnet

./peerto.sh bcm-westus2-hub-rg bcm-westus2-hub-vnet

(may also need to resync the westus2 side - done through portal)
(may also need to update azfinsim_compute_nsg to allow ssh from VNET)

(b) copy ~/.ssh/azfshn.pem to my WSL ~/.ssh
(c) copy ../../config/azfinsim.config to the headnode into azfinsim-run/config/azfinsim.config

(d) ssh to headnode, copy into init-hn.sh, and run it
cat > init-hn.sh
<paste>
chmod u+x init-hn.sh
./init-hn.sh

(e) az login on the headnode

(f) exit
(g) re-ssh

