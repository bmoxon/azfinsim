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

