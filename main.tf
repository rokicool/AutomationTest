provider "azurerm" {
    subscription_id = var.subscription_id
    tenant_id       = var.tenant_id

    features {}
}

resource "azurerm_resource_group" "rg-automation" {
  name     = "rg-${var.project_id}-change-track"
  location = "EastUS2"
}

resource "azurerm_virtual_network" "def-network" {
  name                = "vnet-${var.project_id}"
  location            = azurerm_resource_group.rg-automation.location
  resource_group_name = azurerm_resource_group.rg-automation.name
  address_space       = ["10.0.0.0/16"]
  

  subnet {
    name           = "def-subnet0"
    address_prefix = "10.0.1.0/24"
  }

   tags = {
    environment = var.environment 
    project_id  = var.project_id
  }
}


# Create Network Security Group to access Win VM 
resource "azurerm_network_security_group" "nsg-win-vm" {
  name                = "nsg-win-vm-${var.project_id}-${var.environment}"
  location            = azurerm_resource_group.rg-automation.location
  resource_group_name = azurerm_resource_group.rg-automation.name

security_rule {
    name                       = "allow-rdp-chicago-roki"
    description                = "allow-rdp-chicago-roki"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      =  var.home_ip_address
    destination_address_prefix = "*" 
  }

security_rule {
    name                       = "allow-http"
    description                = "allow-http"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*" 
  }

security_rule {
    name                       = "allow-https"
    description                = "allow-https"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*" 
  }


  tags = {
   # application = var.app_name
    environment = var.environment 
    project_id  = var.project_id
  }
}



# Web Server in Azure
module "win-vm" {
  source = "./win-vm"

  vm_name     = "vm-win-${var.project_id}"
  vm_rg_name  = azurerm_resource_group.rg-automation.name 
  vm_location = azurerm_resource_group.rg-automation.location
  vm_subnet_id= azurerm_virtual_network.def-network.subnet.*.id[0]
  vm_storage_type = "StandardSSD_LRS"
  environment = var.environment
  vm_size     = "Standard_B2s"
  project_id  = var.project_id
  admin_username = var.admin_username
  admin_password = var.admin_password
  network_security_group_id = azurerm_network_security_group.nsg-win-vm.id
}


/*

Automation account 

*/

resource "azurerm_automation_account" "automation_account" {
  name                = "aa-${var.project_id}"
  location            = "EastUS"
  resource_group_name = azurerm_resource_group.rg-automation.name

  sku_name = "Basic"

  tags = {
    environment = var.environment
    project_id  = var.project_id
  }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.project_id}"
  location            = azurerm_resource_group.rg-automation.location
  resource_group_name = azurerm_resource_group.rg-automation.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# WEB VM Public IP
output "win-vm-public_ip" {
  value = module.win-vm.win_vm_public_ip
}