#-- Storage Account
resource "azurerm_storage_account" "azfinsim" {
  name                     = format("%sstorage", var.prefix)
  resource_group_name      = azurerm_resource_group.azfinsim.name
  location                 = azurerm_resource_group.azfinsim.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"
  allow_blob_public_access = true
  tags                      = local.resource_tags
}

#-- Storage Container
resource "azurerm_storage_container" "azfinsim" {
  name                  = "azfinsim"
  storage_account_name  = azurerm_storage_account.azfinsim.name
  container_access_type = "private"
}

#-- Create Storage Container Level SAS Key
data "azurerm_storage_account_blob_container_sas" "azfinsim" {
  connection_string = azurerm_storage_account.azfinsim.primary_connection_string
  container_name    = azurerm_storage_container.azfinsim.name
  https_only        = true

  #ip_address = "X.X.X.X"

  start  = "2021-01-01"
  expiry = "2025-01-01"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}

# nfsblob storage for application access
# see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
# nfsblob has interdependent sets of values, e.g. either ...
# nfsv3_enabled = true, is_hns_enabled = true, account_tier = "Standard", account_kind = "StorageV2"
# nfsv3_enabled = true, is_hns_enabled = true, account_tier = "Premium", account_kind = "BlockBlobStorage"
# AND
# enable_https_trafic_only = false

resource "azurerm_storage_account" "azfinsimxnfs" {
  count                    = local.inc-xnfs ? 1 : 0
  name                     = format("%sstoragexnfs", var.prefix)
  resource_group_name      = azurerm_resource_group.azfinsim.name
  location                 = azurerm_resource_group.azfinsim.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"
  allow_blob_public_access = false
  enable_https_traffic_only = false
  is_hns_enabled           = true
  nfsv3_enabled            = true
  tags                     = local.resource_tags

  network_rules {
    default_action         = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.compute.id
    ]
  }
}


#-- Storage Container
resource "azurerm_storage_container" "azfinsimxnfs" {
  count                 = local.inc-xnfs ? 1 : 0
  name                  = "azfinsimxnfs"
  storage_account_name  = azurerm_storage_account.azfinsimxnfs[0].name
  container_access_type = "private"
}

#-- Create Storage Container Level SAS Key
data "azurerm_storage_account_blob_container_sas" "azfinsimxnfs" {
  count                    = local.inc-xnfs ? 1 : 0
  connection_string = azurerm_storage_account.azfinsimxnfs[0].primary_connection_string
  container_name    = azurerm_storage_container.azfinsimxnfs[0].name
  https_only        = false

  #ip_address = "X.X.X.X"

  start  = "2021-01-01"
  expiry = "2025-01-01"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}
