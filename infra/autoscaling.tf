# task 6 automatic auto scale setting 
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting

resource "azurerm_monitor_autoscale_setting" "lab9_wapp_autoscale" {
    name                = "${local.naming_prefix}custom-autoscale"
    resource_group_name = azurerm_resource_group.lab9_resource_group.name
    location            = azurerm_resource_group.lab9_resource_group.location
    # targetting autoscaling policy to web app plan
    target_resource_id  = azurerm_service_plan.lab9_app_srv_plan.id

    profile {
        name = "default"
        capacity {
            # number of instances that are available for scaling if metrics are not available for evaluation.
            default = 1
            minimum = 1
            # instance limits Maximum
            maximum = 2
        }
        rule {
            metric_trigger {
                # name defining what the rule monitors
                metric_name        = "CpuPercentage"
                # id of the resource being monitored
                metric_resource_id = azurerm_service_plan.lab9_app_srv_plan.id
                # granularity of metrics that the rule monitors
                time_grain         = "PT1M"
                statistic          = "Average"
                # time range for which data is collected
                time_window        = "PT5M"
                # method for collecting data 
                time_aggregation   = "Average"
                # operator that triggers the metric
                operator           = "GreaterThan"
                # Metric threshold to trigger scale action (when CPU utikisatin exceeds an average of 10%)
                threshold          = 10
            }
            scale_action {
                # autoscaling direction 
                direction = "Increase"
                # scaling action to occur once metric is triggered 
                type      = "ChangeCount"
                # number of instances involved in the scaling action
                value     = "1"
                # amount of time to wait since the last scaling action before this action occurs.
                cooldown  = "PT5M"
            }
        }
    }
} 