#-- Networking
resource "azurerm_virtual_network" "azfinsim" {
  name                = format("%s-vnet", var.prefix)
  address_space       = var.address_space
  location            = azurerm_resource_group.azfinsim.location
  resource_group_name = azurerm_resource_group.azfinsim.name
  tags                = local.resource_tags
}
resource "azurerm_subnet" "compute" {
  name                = "compute"
  resource_group_name = azurerm_resource_group.azfinsim.name
  virtual_network_name= azurerm_virtual_network.azfinsim.name
  address_prefixes    = var.compute_subnet_cidr
  enforce_private_link_endpoint_network_policies = true
  #enforce_private_link_service_network_policies = true
  service_endpoints = [
    "Microsoft.Storage"
  ]

}

resource "azurerm_subnet" "infra" {
  name                = "infra"
  resource_group_name = azurerm_resource_group.azfinsim.name
  virtual_network_name= azurerm_virtual_network.azfinsim.name
  address_prefixes    = var.infra_subnet_cidr
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "bastion" {
  name                = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.azfinsim.name
  virtual_network_name= azurerm_virtual_network.azfinsim.name
  address_prefixes    = var.bastion_subnet_cidr
  enforce_private_link_endpoint_network_policies = true
}

#-- private DNS zone for public endpoints
resource "azurerm_private_dns_zone" "azfinsim" {
  name                = "private.azfinsim.com"
  resource_group_name = azurerm_resource_group.azfinsim.name
}

# ToDo: maybe want to conditionally deploy based on variable (?)
#resource "azurerm_public_ip" "azfinsim" {
#  name                = format("%s-pubip", var.prefix)
#  location            = azurerm_resource_group.azfinsim.location
#  resource_group_name = azurerm_resource_group.azfinsim.name
#  allocation_method   = "Dynamic"
#  domain_name_label   = "azfinsim"
#  tags                = local.resource_tags
#}
#resource "azurerm_network_interface" "nic" {
#  name                = format("%s-nic", var.prefix)
#  location            = azurerm_resource_group.azfinsim.location
#  resource_group_name = azurerm_resource_group.azfinsim.name
#
#  ip_configuration {
#    name                          = "azfinsimipconfig"
#    subnet_id                     = azurerm_subnet.azfinsim.id
#    private_ip_address_allocation = "Dynamic"
#    public_ip_address_id          = azurerm_public_ip.azfinsim.id
#  }
#  tags = local.resource_tags
#}
