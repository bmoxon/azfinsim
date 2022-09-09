#-- Application insights

# original ... Classic mode
# needs to be moved to Workspace mode (at least in westus3)

# terraform error ...
# "Region doesn't support Classic resource mode for Application Insights resources."

#resource "azurerm_application_insights" "azfinsim" {
#  name                = format("%s-appinsights", var.prefix)
#  resource_group_name = azurerm_resource_group.azfinsim.name
#  location            = azurerm_resource_group.azfinsim.location
#  application_type    = "other"
#  tags                = local.resource_tags
#}

# workspace mode from
# https://github.com/hashicorp/terraform-provider-azurerm/blob/main/website/docs/r/application_insights.html.markdown

resource "azurerm_log_analytics_workspace" "azfinsim" {
  name                = "loganalytics-workspace"
  location            = azurerm_resource_group.azfinsim.location
  resource_group_name = azurerm_resource_group.azfinsim.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "azfinsim" {
  name                = format("%s-appinsights", var.prefix)
  location            = azurerm_resource_group.azfinsim.location
  resource_group_name = azurerm_resource_group.azfinsim.name
  workspace_id        = azurerm_log_analytics_workspace.azfinsim.id
  application_type    = "other"
  tags                = local.resource_tags
}
