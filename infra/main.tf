# terraform config block

terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>3.30.0"
    }
  }

  backend "azurerm" {
    key              = "terraform.tfstate"
    use_oidc         = true
    use_azuread_auth = true
  }
}
#-------------------------------------------------------------

# ms provider config block
provider "azurerm" {
  # mandatory features block
  features {}
  use_oidc = true
}

#-------------------------------------------------------------

# resource group containing web app deployment 
resource "azurerm_resource_group" "lab9_resource_group" {
  name = "${local.naming_prefix}resource_group1"
  # region resource group is deployed in
  location = var.deployment_location
}

#-------------------------------------------------------------
