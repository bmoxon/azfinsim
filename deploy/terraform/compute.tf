#-- Compute resources - standalone VMs (bastion accessible)
#-- way to optionally provide public ip access and ssh configuration (?)

# look at note at end of https://stackoverflow.com/questions/63413564/terraform-azure-vm-ssh-key

# nice full example with publicip, nsg, ... at
# https://docs.microsoft.com/en-us/azure/developer/terraform/create-linux-virtual-machine-with-infrastructure

resource "tls_private_key" "azfinsim_headnode_ssh" {
    algorithm = "RSA"
    rsa_bits = 4096
}

# Create public ip
resource "azurerm_public_ip" "azfinsim_headnode_vm" {
    name                         = "azfinsim_headnode_vm_pubip"
    location                     = azurerm_resource_group.azfinsim.location
    resource_group_name          = azurerm_resource_group.azfinsim.name
    allocation_method            = "Dynamic"
    # ??domain_name_label            = "csvm${random_integer.server.result}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "azfinsim_headnode_vm" {
    name                = "azfinsim_compute_nsg"
    location                     = azurerm_resource_group.azfinsim.location
    resource_group_name          = azurerm_resource_group.azfinsim.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = local.resource_tags
}

# Create network interface

resource "azurerm_network_interface" "azfinsim_headnode_vm" {
  name                = "headnode-vm-nic"
  location            = azurerm_resource_group.azfinsim.location
  resource_group_name = azurerm_resource_group.azfinsim.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.compute.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azfinsim_headnode_vm.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "azfinsim_headnode_vm" {
    network_interface_id      = azurerm_network_interface.azfinsim_headnode_vm.id
    network_security_group_id = azurerm_network_security_group.azfinsim_headnode_vm.id
}

resource "azurerm_linux_virtual_machine" "azfinsim_headnode_vm" {
    location             = azurerm_resource_group.azfinsim.location
    resource_group_name  = azurerm_resource_group.azfinsim.name
    name = "headnode-vm"
    computer_name = "headnode"
    admin_username = "azfinsim"
    admin_password = "lcCU3Ii8GbNjUHi1bs8="
    size = var.headnode_vm_size

  network_interface_ids = [
    azurerm_network_interface.azfinsim_headnode_vm.id,
  ]

  os_disk {
    name                 = "azfinsim_headnode_vm_osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

    disable_password_authentication = false

    admin_ssh_key {
        username = "azfinsim"
        public_key = tls_private_key.azfinsim_headnode_ssh.public_key_openssh
    }

    tags = local.resource_tags
}


