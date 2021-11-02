#-- Redis Cache: Premium P1 
#-- see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/redis_cache
#-- Firewall and private endpoint details and more options (github repo published module)
#-- https://github.com/kumarvna/terraform-azurerm-redis

# NOTE: the Name used for Redis needs to be globally unique
resource "azurerm_redis_cache" "azfinsim" {
  count               = local.dbg-noredis ? 0 : 1
  name                = format("%scache", var.prefix)
  resource_group_name = azurerm_resource_group.azfinsim.name
  location            = azurerm_resource_group.azfinsim.location
  capacity            = 1
  family              = local.env-prod ? "P" : "C"
  sku_name            = local.env-prod ? "Premium" : "Standard"
  enable_non_ssl_port = true
  minimum_tls_version = "1.2"

  redis_configuration {
  }
  tags                = local.resource_tags
}

#resource "azurerm_redis_firewall_rule" "azfinsim" {
#  name                = "redisComputeAccessFirewall"
#  redis_cache_name    = azurerm_redis_cache.azfinsim[0].name
#  resource_group_name = azurerm_resource_group.azfinsim.name
#  start_ip            = cidrhost(azurerm_subnet.compute.address_prefix, 1)
#  end_ip              = cidrhost(azurerm_subnet.compute.address_prefix, var.compute_nhosts_max)
#}

  # Creating Private Endpoint requires, VNet name and address prefix to create a subnet
  # By default this will create a `privatelink.redis.cache.windows.net` DNS zone. 
  # To use existing private DNS zone specify `existing_private_dns_zone` with valid zone name
  # Private endpoints doesn't work If using `subnet_id` to create redis inside a specified VNet.
  #enable_private_endpoint       = true
  #virtual_network_name          = azurerm_virtual_network.azfinsim.name
  #private_subnet_address_prefix = azurerm_subnet.azfinsim.address_prefixes
  #existing_private_dns_zone     = azurerm_private_dns_zone.azfinsim.name

  # (Optional) To enable Azure Monitoring for Azure Cache for Redis
  # (Optional) Specify `storage_account_name` to save monitoring logs to storage. 
  # log_analytics_workspace_name = "loganalytics-we-sharedtest2"


resource "azurerm_private_endpoint" "azfinsim-redis" {
  name                = "azfinsim-redis-ep"
  location            = azurerm_resource_group.azfinsim.location
  resource_group_name = azurerm_resource_group.azfinsim.name
  subnet_id           = azurerm_subnet.infra.id

  private_service_connection {
    name                           = "azfinsim-redis-privateserviceconnection"
    private_connection_resource_id = local.dbg-noredis ? null : azurerm_redis_cache.azfinsim[0].id
    is_manual_connection           = false
    subresource_names              = ["cache"]
  }
}