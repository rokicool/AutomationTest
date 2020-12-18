// the `exit_code_hack` is to keep the VM Extension resource happy
locals {

  install_iis_command   = "Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
  
  exit_code_hack       = "exit 0"
  powershell_command   = "${local.install_iis_command}; ${local.exit_code_hack}"
}

resource "azurerm_virtual_machine_extension" "install-iis" {
  name                 = "install-iis"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}