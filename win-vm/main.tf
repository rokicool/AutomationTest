#######################################
## Windows VM          Server - Main ##
#######################################

# Get a Static Public IP 
resource "azurerm_public_ip" "windows-vm-ip" {
  name                = "pub-ip-${var.vm_name}-${var.project_id}-${var.environment}"
  location            = var.vm_location
  resource_group_name = var.vm_rg_name
  allocation_method   = "Static"
  
  tags = { 
    environment = var.environment 
  }
}

# Create Network Card for web VM buyusa
resource "azurerm_network_interface" "windows-vm-nic" {
  depends_on=[azurerm_public_ip.windows-vm-ip]

  name                      = "${var.vm_name}-vm-nic-${var.project_id}-${var.environment}"
  location                  = var.vm_location
  resource_group_name       = var.vm_rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows-vm-ip.id
  }

  # dns_servers                   = var.dns_servers

  tags = { 
    #application = var.app_name
    environment = var.environment 
  }
}

# Create Windows Server
resource "azurerm_windows_virtual_machine" "windows-vm" {
  depends_on=[azurerm_network_interface.windows-vm-nic]

  name                  = "vm-${var.vm_name}-${var.project_id}-${var.environment}"
  location              = var.vm_location
  resource_group_name   = var.vm_rg_name
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.windows-vm-nic.id]
  patch_mode            = "Manual"
  
  computer_name         = var.vm_name
  admin_username        = var.admin_username
  admin_password        = var.admin_password

  os_disk {
    name                 = "os-disk-vm-${var.vm_name}-${var.project_id}-${var.environment}"
    caching              = "ReadWrite"
    storage_account_type = var.vm_storage_type
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.windows-2016-sku
    version   = "latest"
  }

  enable_automatic_updates = false
  provision_vm_agent       = true

  tags = {
    #application = var.app_name
    environment = var.environment 
  }
}

resource "azurerm_network_interface_security_group_association" "vm-nsg-association" {
  network_interface_id      = azurerm_network_interface.windows-vm-nic.id
  network_security_group_id = var.network_security_group_id
}
