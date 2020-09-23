# lm-logs-azure-windows-vm
 Auto configuration files for setting up Windows Azure Diagnostics(WAD) to send to LM Logs EventHub integration

### Windows Virtual Machines (using Windows Azure Diagnostics extension)

Forwarding Windows VM's system and application logs requires [installation of diagnostic extension](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/diagnostics-extension-windows-install) on the machine.

#### Prerequisites

* [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* [Sign to Azure in with Azure CLI](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli?view=azure-cli-latest): execute `az login`
* Install via PowerShell:
`Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi`

#### Configuration

* Download the configuration script: `Invoke-WebRequest -Uri https://raw.githubusercontent.com/stevevillardi/lm-logs-azure-windows-vm/master/LMLogs-WADConfiugration.ps1 -OutFile .\LMLogs-WADConfiugration.ps1`
* execute it to create the storage account needed by the extension, and the configuration files: `.\LMLogs-WADConfiugration.ps1 -lm_company_name <LM company name>`
* update `wad_public_settings.json` to configure types of [event logs](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/diagnostics-extension-schema-windows#windowseventlog-element) (`Applicaiton, System, Setup, Security, etc`) and their levels (`Info, Warning, Critical`) to collect
* excecute `az vm extension set --publisher Microsoft.Azure.Diagnostics --name IaaSDiagnostics --version 1.18 --resource-group ##AZ_LOGS_RG_NAME## --vm-name ##VM-NAME## --protected-settings wad_protected_settings.json --settings wad_public_settings.json`
