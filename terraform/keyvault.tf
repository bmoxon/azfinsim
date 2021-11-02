#-- Keyvault - name must be unique due to soft delete retaining the vault 
resource "azurerm_key_vault" "azfinsim" {
  name                                = format("%svault-%s", var.prefix, random_string.suffix.result)
  resource_group_name                 = azurerm_resource_group.azfinsim.name
  location                            = azurerm_resource_group.azfinsim.location
  tenant_id                           = data.azurerm_client_config.current.tenant_id
  sku_name                            = "standard"
  enabled_for_deployment              = true
  enabled_for_template_deployment     = true
  #-- no longer required, enabled by default
  #soft_delete_enabled                 = true
  soft_delete_retention_days          = 7
  purge_protection_enabled            = false

#  enforce_private_link_endpoint_network_policies = true
#  enforce_private_link_service_network_policies = true

  #-- bug in cloudshell makes client_config.object_id blank, so use the one we queried from the cli
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    #object_id = data.azurerm_client_config.current.object_id
    object_id = data.external.UserAccount.result.objectId
    key_permissions = [
    ]
    secret_permissions = [
      "get",
      "set",
      "list",
      "delete",
      "purge",
    ]
    storage_permissions = [
    ]
  }

  #-- delegate access to azfinsim service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azuread_service_principal.azfinsim.id
 
    key_permissions = [
    ]
    secret_permissions = [
      "get",
      "set",
      "list",
      "delete",
      "purge",
    ]
  }
  #-- delegate access to Microsoft Azure Batch service
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.external.batchservice.result.objectId
 
    key_permissions = [
    ]
    secret_permissions = [
      "get",
      "set",
      "list",
      "delete",
      "recover",
    ]
  }
  tags = local.resource_tags
}

# private endpoint
# had to work through errors, add subresource_names
# https://github.com/hashicorp/terraform-provider-azurerm/issues/9058
# and this (using vaultcore)
# https://github.com/hashicorp/terraform-provider-azurerm/issues/10501
# (maybe need both?)

resource "azurerm_private_endpoint" "azfinsim-kv" {
  name                = "azfinsim-keyvault-ep"
  location            = azurerm_resource_group.azfinsim.location
  resource_group_name = azurerm_resource_group.azfinsim.name
  subnet_id           = azurerm_subnet.infra.id

  private_service_connection {
    name                           = "azfinsim-keyvault-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.azfinsim.id
    is_manual_connection           = false
    # bcm azuread > 2.0
    #subresource_names              = ["vaultcore"]
    subresource_names              = ["vault"]
  }
}
