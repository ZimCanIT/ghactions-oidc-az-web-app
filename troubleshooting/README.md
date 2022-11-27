# Errors encountered during deployment

Error(s) encountered during the build of this project; with steps showing how I overcame them

## Errors

1. Terraform initialised in an empty directory!

![1-error](https://user-images.githubusercontent.com/77082071/204030528-14af0dc0-d9ec-494c-960e-d6d50d4851c4.png)

```
2022-11-23T16:36:45.133Z [INFO]  CLI command args: []string{"init", "-backend-config=storage_account_name=***", "-backend-config=container_name=***", "-backend-config=resource_group_name=***"}
Terraform initialized in an empty directory!
```

Thoeory: the working directory needs to be set to where the terraform config files are within the repository: `lab9a-implement-web-apps\infra`

Resolved by setting the working directory for all steps in the job. In addition to upgrading the github actions checkout tool to v3. 

`pull-req.yaml` original terraform init declaration

```
jobs: 
  deploy-infra:
    runs-on: ubuntu-latest
    steps:
    # Checkout the repository to the GitHub Actions runner
    - name: Checkout
      uses: actions/checkout@v2
```

```
jobs: 
  pr-infra-check:
    runs-on: ubuntu-latest
    defaults: 
      run:
        working-directory: infra

    steps:
    # Checkout the repository to the GitHub Actions runner
    - name: Checkout
      uses: actions/checkout@v3
```



2. Error after applying a push to main after testing changing the working directory

```
https://login.microsoftonline.com/ with  tenant ***

│ Error: Failed to get existing workspaces: containers.Client#ListBlobs: 

Failure responding to request: 

StatusCode=403 -- Original Error: autorest/azure: Service returned an error. Status=403 Code="AuthorizationPermissionMismatch" 

Message="This request is not authorized to perform this operation using this permission.\nRequestId:00000000-0000-0000-0000-000000000000\nTime:2022-11-24T10:15:50.1271435Z"
```

Theory: either the service principal set as the federated identity does not have the permissions to access the storage account created to store terraform state data. The message: ` Failed to get existing workspaces: containers.Client#ListBlobs` could be interpreted as the SPN not being able to enumarate the storage account's container to view the blobs. 

Resolved by ensuring the tenant ID and subscription set matched the environment the storage account was setup in. In addition to assigning the built-in-role: `Storage Blob Data Owner` over the scope of the storage account conatiner created for this project to the service principal. Access was not assigned over the storage account so as to apply the principle of least priviledge. After application the first deployment was a success and the initial infrastructure was depoyed in azure, a resource group.

![assigned-storage-blob-data-owner-role-to-spn-2-error](https://user-images.githubusercontent.com/77082071/204030713-0e9e8c73-6370-40f0-8fdf-86736905a06c.png)

![2-error-successful-deployment-post-rbac-assignment](https://user-images.githubusercontent.com/77082071/204030630-e450f3ad-8f51-4244-9830-4d89b550fee3.png)

3. Application runtime stack set incorrectly

```
Error: -24T12:11:38.496Z [ERROR] vertex "azurerm_windows_web_app.lab9_app_srv" error: expected site_config.0.application_stack.0.php_version to be one of [7.4], got v7.4
```

Theory: minor syntactical error - resolved by declaring php runtime stack version correctly in `web-app.tf`

```
application_stack {
    current_stack = "php"
    # PHP 7.4 will reach EOL on 30/11/2022
    # https://github.com/Azure/app-service-linux-docs/tree/master/Runtime_Support
    php_version = "7.4"
}
```

4. Failure on `terraform check -fmt` with exit code 3 in github actions workflow

```
main.tf
outputs.tf
variables.tf
web-app.tf
Error: Terraform exited with code 3.
Error: Process completed with exit code 1.
```

Theory: the purpose of terraform fmt -check ensure terraform config files are formatted correctly. Increasing ease of code readability. Exit code 3 does not make any contribution to the code asides from formatting. Any other exit code besides 0, indicates the input hasn't been formatted. Resolved by adding an additional format step prior to checking for formatting within `pull-req.yaml`. Ensuring all commits that are merged to the main branch include formatted terraform config files. [Discussion on exit code 3](https://github.com/hashicorp/terraform/issues/31543)

Additional step added to `pull-req.yaml`: 

```
- name: Terraform format
  id: fmt
  run: |
    terraform fmt 
    terraform fmt -check
```


5. Autoscaling `scale action rule` error

```
│ Error: Insufficient scale_action blocks
│ 
│   on autoscaling.tf line 20, in resource "azurerm_monitor_autoscale_setting" "lab9_wapp_autoscale":
│   20:     rule {
│ 
│ At least 1 "scale_action" blocks are required.
╵
╷
│ Error: Unsupported block type
│ 
│   on autoscaling.tf line 41, in resource "azurerm_monitor_autoscale_setting" "lab9_wapp_autoscale":
│   41:     scale_action {
│ 
│ Blocks of type "scale_action" are not expected here.
╵
Error: Terraform exited with code 1.
Error: Process completed with exit code 1.
```

Resolved by referencing documentation as a scale action block was already defined, justnot indented within rules block. Set `azurerm_monitor_autoscale_setting` resource block to:

```
rule {
    metric_trigger {
        # name defining what the rule monitors
        metric_name        = "CPU Percentage"
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
        # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers
        metric_namespace   = "microsoft.web/appservice"
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
```

6. Metric namespace incorrectly set 

```
│ Error: creating Monitor Autoscale Setting: (Name "az104-9a-" / Resource Group "az104-9a-rg1"): insights.AutoscaleSettingsClient#CreateOrUpdate: 

Failure responding to request: StatusCode=400 -- Original Error: autorest/azure: Service returned an error. 

Status=400 Code="BadRequest" Message="{\"code\":\"BadRequest\",\"message\":\"Detect invalid value: microsoft.web/appservice for query parameter: 'metricnamespace', the value must be: Microsoft.Web/serverfarms if the query parameter is provided, you can also skip this optional query parameter.\"}"
│ 
│   with azurerm_monitor_autoscale_setting.lab9_wapp_autoscale,
│   on autoscaling.tf line 4, in resource "azurerm_monitor_autoscale_setting" "lab9_wapp_autoscale":
│    4: resource "azurerm_monitor_autoscale_setting" "lab9_wapp_autoscale" {
```

Theory: incorrect reference to metric namespace pointing to azure web app service. With the metric resource id being set, the optional metric_namespace varaible was removed to resolve this issue, in addition to setting a compatible value for the metric name.

7. Error applying terraform config after manually deleting resources

```
│ Error: Error acquiring the state lock
│ 
│ Error message: state blob is already locked
│ Lock Info:
│   ID:        2e7f1aa0-43e9-4535-bbdd-64a61b45fcf1
│   Path:      ***/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       runner@fv-az290-522
│   Version:   1.3.5
│   Created:   2022-11-25 13:39:15.895206577 +0000 UTC
│   Info:      
│ 
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
```

Resolved by navigating to the blob containing the terraform state and breaking the locke d lease status on the blob in the Azure portal.

![7-breaking-lock-on-blob](https://user-images.githubusercontent.com/77082071/204030756-b6f6d6cc-3abc-480a-ad81-c7a929881b8a.png)

![7-breaking-lease-confirmation](https://user-images.githubusercontent.com/77082071/204030781-032a83d9-ebae-4350-b19e-597e9438b6e1.png)

Terraform lock the state file during runs to prevent parralel modifications to the state file. Evidenced by a leased status of: `Leased` on the blob containing the state file.

Alternate methods of releasing the lock would be via terraform: 

`terraform force-unlock [insert lock id here]`

As well as via the azure cli: 

```
az storage blob lease break -b terraform.tfstate -c myAzureStorageAccountContainerName --account-name "myAzureStorageAccountName" --account-key "myAzureStorageAccountAccessKey"
```

Once the lock was removed, the next run in GitHub actions confirmed terraform could acquire the state lock

![7-state-lock-acquired](https://user-images.githubusercontent.com/77082071/204030835-cd47cbd1-7c33-4566-9516-75903c21f648.png
