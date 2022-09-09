resource "azurerm_public_ip" "azfinsim" {
  name                = format("%s-bastion-ip", var.prefix)
  location            = azurerm_resource_group.azfinsim.location
  resource_group_name = azurerm_resource_group.azfinsim.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "azfinsim" {
  name                = format("%s-bastion", var.prefix)
  location            = azurerm_resource_group.azfinsim.location
  resource_group_name = azurerm_resource_group.azfinsim.name

  ip_configuration {
    name                 = "compute-subnet"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.azfinsim.id
  }
}
