#random integer for unique resource naming
resource "random_integer" "rand_val" {
    min = 1000
    max = 5000
}

#-------------------------------------------------------------

# web app plan - task 1
resource "azurerm_service_plan" "lab9_app_srv_plan" {
    name                = "${local.naming_prefix}wapp-service-plan-${random_integer.rand_val.result}"
    resource_group_name = azurerm_resource_group.lab9_resource_group.name
    # region where app service should exist is the same as the resource group it's deployed in 
    location            = azurerm_resource_group.lab9_resource_group.location
    # standard SKU for this service plan - $73:00 USD /month
    sku_name            = "S1"
    os_type             = "Windows"
}
# web app service task 1
resource "azurerm_windows_web_app" "lab9_app_srv" {
    name                = "${local.naming_prefix}wapp-service-${random_integer.rand_val.result}"
    resource_group_name = azurerm_resource_group.lab9_resource_group.name
    location            = azurerm_service_plan.lab9_app_srv_plan.location
    service_plan_id     = azurerm_service_plan.lab9_app_srv_plan.id

    # ensuring web app is enabled 
    enabled = true

    site_config {
        # ensuring web app is always on 
        always_on = true
        
        application_stack {
            current_stack = "php"
            # PHP 7.4 will reach EOL on 30/11/2022
            # https://github.com/Azure/app-service-linux-docs/tree/master/Runtime_Support
            php_version = "7.4"
        }
    }

    # explicit dependancy set on creation of app service plan 
    depends_on = [azurerm_service_plan.lab9_app_srv_plan]
}

#-------------------------------------------------------------

# staging deployment slot - task 2
resource "azurerm_windows_web_app_slot" "lab9_wapp_slot" {
  name           = "${local.naming_prefix}staging"
  app_service_id = azurerm_windows_web_app.lab9_app_srv.id 
  #enabling web app slot
  enabled = true 

  site_config {}
}

#-------------------------------------------------------------

# manage an App Service Source Control Slot - task 3
# need to set localgit/ftps credentuals in Azure portal. In addition to copying the "Git Clone URL" to notepad
resource "azurerm_app_service_source_control_slot" "lab9_wapp_sc_slot" {
    slot_id  = azurerm_windows_web_app_slot.lab9_wapp_slot.id 
    # using local git config for deployment slot 
    use_local_git = true
}

#-------------------------------------------------------------
