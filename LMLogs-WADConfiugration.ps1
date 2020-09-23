#
# Copyright (C) 2020 LogicMonitor, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

$lm_company_name = "lmstevenvillardi"

Write-Host "Collecting VM Info"
$vm_info = ((Invoke-WebRequest -Uri 169.254.169.254/metadata/instance?api-version=2017-08-01 -Headers @{"Metadata"="true"}).Content | ConvertFrom-Json).compute

$subscription_id = $vm_info.subscriptionId
Write-Host "subscription id = $subscription_id"
$vm_resource_group= $vm_info.resourceGroupName
Write-Host "resource group = $vm_resource_group"
$vm_name= $vm_info.name
Write-Host "vm name = $vm_name"
$location= $vm_info.location
Write-Host "location = $location"

$vm_resource_id=$(az vm show --subscription $subscription_id -g $vm_resource_group -n $vm_name --query "id" -o tsv)
if ($vm_resource_id){
    Write-Host "resource id = $vm_resource_id"
}
else {
    Write-Host "can't determine resource id"
    exit -1
}

$event_hub_namespace="lm-logs-$lm_company_name-$location"
$event_hub_group="$event_hub_namespace-group"
$event_hub_name="log-hub"
$event_hub_auth_name="sender"

Write-Host "reading the event hub authorization key:"
Write-Host "    resource group = $event_hub_group" 
Write-Host "    event hub = $event_hub_namespace/$event_hub_name"
Write-Host "    auth name = $event_hub_auth_name"
$event_hub_auth_key= $(az eventhubs eventhub authorization-rule keys list --subscription $subscription_id --resource-group $event_hub_group --namespace-name $event_hub_namespace --eventhub-name $event_hub_name --name $event_hub_auth_name --query "primaryKey" -o tsv)
if (!$event_hub_auth_key) {
    Write-Host "can't read the authorization key"
    exit -1
}

$event_hub_uri="https://$event_hub_namespace.servicebus.windows.net/$event_hub_name"
Write-Host "generating the event hub sas uri"

$storage_name=("diag$location$vm_name").Replace('[^a-zA-Z]','').ToLower()
$storage_group=$vm_resource_group
if ($storage_name.Length -gt 24){
    $storage_name=$storage_name.substring(0, 24)
}

Write-Host "checking if the storage account exists:"
Write-Host "    resource group = $storage_group"
Write-Host "    storage account = $storage_name"
if ($storage_name -ne $(az storage account show --subscription $subscription_id -g $storage_group -n $storage_name --query name -o tsv)){
    Write-Host "creating the storage account"
    az storage account create --subscription $subscription_id -g $storage_group -n $storage_name -l $location --sku Standard_LRS
    if(!$?){
        Write-Host "couldn't create the storage account"
        exit -1
    }
}

Write-Host "generating the storage account sas token"
$storage_token_expiry=(get-date).AddYears(10).ToString("yyyy-MM-ddTHH:mmZ")
$storage_account_sas_token=$(az storage account generate-sas --account-name $storage_name --expiry $storage_token_expiry --permissions wlacu --resource-types co --services bt -o tsv)
if (!$?){
    Write-Host "couldn't generate the token"
    exit -1
}
