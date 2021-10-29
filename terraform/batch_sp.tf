#-- Get the objectid for the Azure Batch Service (needed for batch provider registration & keyvault access policy)
#-- [Note however that objectid should be constant: ddbf3205-c6bd-46ae-8127-60eb93363864]
data "external" "batchservice" {
  program = ["az", "ad", "sp", "show", "--id", "MicrosoftAzureBatch", "--query", "{objectId:objectId, appId:appId}"]
}

data "azuread_client_config" "current" {}

#-- Register the application 
resource "azuread_application" "azfinsim" {
  display_name               = "azfinsim"
  web {
    homepage_url             = "https://github.com/mkiernan/azfinsim"
  }
  owners                     = [data.azuread_client_config.current.object_id]
  fallback_public_client_enabled = true
}

resource "azuread_service_principal" "azfinsim" {
  application_id                  = azuread_application.azfinsim.application_id
  app_role_assignment_required    = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "azfinsim" {
  service_principal_id = azuread_service_principal.azfinsim.object_id

  lifecycle {
    ignore_changes = [value, end_date]
  }
}

resource "azurerm_role_assignment" "azfinsim" {
  scope                             = data.azurerm_subscription.current.id
  role_definition_name              = "Contributor"
  principal_id                      = azuread_service_principal.azfinsim.object_id
  skip_service_principal_aad_check  = true
}
