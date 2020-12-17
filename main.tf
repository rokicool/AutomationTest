provider "azurerm" {
    subscription_id = var.subscription_id
    tenant_id       = var.tenant_id

    features {}
}

resource "azurerm_resource_group" "rg-automation" {
  name     = "rg-${var.project_id}-change-track"
  location = "EastUS2"
}

module "winserv" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.rg-automation.name
  is_windows_image    = true
  vm_hostname         = "vm-${var.project_id}-win" // line can be removed if only one VM module per resource group
  admin_password      = var.admin_password
  admin_username      = var.admin_username
  vm_size             = "Standard_B2s"
  vm_os_simple        = "WindowsServer"
  public_ip_dns       = ["ip-${var.project_id}-win"] // change to a unique name per datacenter region
  vnet_subnet_id      = module.network.vnet_subnets[0]

  depends_on = [azurerm_resource_group.rg-automation]
}


module "network-security-group" {
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.rg-automation.name
  security_group_name   = "nsg-rg-automation"
  source_address_prefix = ["0.0.0.0/0"]
  predefined_rules = [
    {
      name     = "SSH"
      priority = "500"
    },
    {
      name     = "HTTP"
      priority = "501"
    },
    {
      name     = "HTTPS"
      priority = "502"
    }
  ]

  custom_rules = [
    {
      name                   = "allow-ssh-from-chi"
      priority               = 201
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "tcp"
      source_port_range      = "*"
      destination_port_range = "22"
      source_address_prefix  = "76.229.200.36/32"
      description            = "Allow SSH from Chicago appt"
    },
    {
      name                    = "allow-rdp-from-chi"
      priority                = 202
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "tcp"
      source_port_range       = "*"
      destination_port_range  = "3389"
      source_address_prefixes = ["76.229.200.36/32"]
      description             = "Allow RDP from Chicago apt"
    },
  ]

  tags = {
    environment = var.environment
    project_id  = var.project_id
  }

  depends_on = [azurerm_resource_group.rg-automation]
}

module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.rg-automation.name
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  depends_on = [azurerm_resource_group.rg-automation]
}



resource "azurerm_subnet_network_security_group_association" "roki-automation-nsg-assoc" {
  subnet_id                 = module.network.vnet_subnets[0]
  network_security_group_id = module.network-security-group.network_security_group_id
}

output "windows_vm_public_name" {
  value = module.winserv.public_ip_dns_name
}