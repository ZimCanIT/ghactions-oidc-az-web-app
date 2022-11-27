variable "deployment_location" {
    type = string
    description = "Location within which web app will be dpeloyed"
    default = "West Europe"
}

#-------------------------------------------------------------

locals {
    naming_prefix="az104-9a-"

    common_tags = {
        env="dev",
        owner="zimcanit",

    }

    # http invokation command required for task 6 where an infinite loop of HTTP requests are sent to the web app
    invokation_command  = "while ($true) { Invoke-WebRequest -Uri ${azurerm_windows_web_app.lab9_app_srv.default_hostname} }"
}

#-------------------------------------------------------------