$rg_name = "github-actions-OIDC-storage-account-rg"
$deployment_location  = "West Europe"
$container_name = "terraform-state"
$sku_name = "Standard_GRS"
# random int for storage account name as the name of a storage account needs to be unique 
$rand_val = Get-Random -Minimum 10000 -Maximum 20000
$storage_acc_name = "tfmstorageacc${rand_val}"


Write-Host -ForegroundColor Green "Creating resource group..."

az group create --name $rg_name --location $deployment_location --tags "project=github-actions-oidc"  "env=dev" "owner=zimcanit"

Write-Host -ForegroundColor Green "Creating storage account..."

# create storage account
az storage account create --resource-group $rg_name --location $deployment_location --name $storage_acc_name --sku $sku_name

Write-Host -ForegroundColor Green "Creating storage container..."

az storage container create --name $container_name --account-name $storage_acc_name

Write-Host -ForegroundColor Green "Set storage account name below as a GitHub actions secret..."

az storage accont show --name $storage_acc_name --resource-group $rg_name