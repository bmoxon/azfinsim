#-- Get the objectid for the Azure Batch Service (needed for batch provider registration & keyvault access policy)
#-- [Note however that objectid should be constant: ddbf3205-c6bd-46ae-8127-60eb93363864]
data "external" "batchservice" {
  program = ["az", "ad", "sp", "show", "--id", "MicrosoftAzureBatch", "--query", "{objectId:objectId, appId:appId}"]
}

#-- This section is needed if your subscription is not setup for Azure Batch already
#-- Resource Provider Registration
#-- https://docs.microsoft.com/en-us/azure/batch/batch-account-create-portal#allow-azure-batch-to-access-the-subscription-one-time-operation

#resource "azurerm_resource_provider_registration" "batchservice" {
#  name = "Microsoft.Batch"
#}

#-- Create Role Assignment to allow Azure Batch Service to access the subscription
#resource "azurerm_role_assignment" "batchservice" {
#  scope                = data.azurerm_subscription.current.id
#  role_definition_name = "Contributor"
#  principal_id         = data.external.batchservice.result.objectId
#  #principal_id         = azurerm_resource_provider_registration.batchservice.result.objectId
#}

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

#-- RBAC custom role definition for service principal
#-- https://docs.microsoft.com/en-us/azure/batch/batch-aad-auth#use-integrated-authentication
#-- https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsoftbatch
#-- remove the pools/certificates lines if you don't want users messing with those

#resource "azurerm_role_definition" "azfinsim" {
#  role_definition_id = "00000000-0000-0000-0000-000000000000"
#  name               = "azfinsim-custom-role-definition"
#  description        = "Azure Batch Custom Job Submitter & Pool Manager Role Definition"
#  scope              = data.azurerm_subscription.current.id
#
#  permissions {
#    actions = [
#      "Microsoft.Batch/batchAccounts/pools/*",
#      "Microsoft.Batch/batchAccounts/applications/*",
#      "Microsoft.Batch/batchAccounts/certificates/*",
#      "Microsoft.Batch/batchAccounts/read",
#      "Microsoft.Batch/batchAccounts/listKeys/action",
#      "Microsoft.Batch/locations/quotas/read",
#      "Microsoft.Authorization/*/read",
#      "Microsoft.ResourceHealth/availabilityStatuses/read",
#      "Microsoft.Resources/subscriptions/resourceGroups/read",
#      "Microsoft.Resources/deployments/*",
#      "Microsoft.Support/*"
#    ]
#    data_actions = [
#      "Microsoft.Batch/batchAccounts/jobSchedules/write",
#      "Microsoft.Batch/batchAccounts/jobSchedules/delete",
#      "Microsoft.Batch/batchAccounts/jobSchedules/read",
#      "Microsoft.Batch/batchAccounts/jobs/write",
#      "Microsoft.Batch/batchAccounts/jobs/delete",
#      "Microsoft.Batch/batchAccounts/jobs/read"
#    ]
#    not_actions = []
#  }
#
#  assignable_scopes = [
#    data.azurerm_subscription.current.id
#  ]
#}
##-- RBAC custom role assignment for batch 
#
#resource "azurerm_role_assignment" "azfinsim" {
#  name                             = "00000000-0000-0000-0000-000000000000"
#  scope                             = data.azurerm_subscription.current.id
#  role_definition_id                = azurerm_role_definition.azfinsim.role_definition_resource_id
#  principal_id                      = azuread_service_principal.azfinsim.object_id
#  skip_service_principal_aad_check  = true
#}

resource "azurerm_role_assignment" "azfinsim" {
  scope                             = data.azurerm_subscription.current.id
  role_definition_name              = "Contributor"
  principal_id                      = azuread_service_principal.azfinsim.object_id
  skip_service_principal_aad_check  = true
}
