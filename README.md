# GitHub Actions OIDC auth Azure web app

Hosting a web site on Azure Web Apps. All whilst implementing a deployment slot. IaC tooling used: terraform. OIDC is used to create resources and store state data in a storage container. Architecture: 

![lab-9a-architectural-diagram](https://user-images.githubusercontent.com/77082071/204031086-7ba09645-026b-43c5-887f-265c7dc1c225.png)

Tasks acheived within configuration: 

* Task 1: Create an Azure web app
* Task 2: Create a staging deployment slot
* Task 3: Configure web app deployment settings
* Task 4: Deploy code to the staging deployment slot
* Task 5: Swap the staging slots
* Task 6: Configure autoscaling
 
Within the GitHub actions workflows folder there is: `pull-req.yaml` and `push.yaml`; which are representative of the standard terraform workflow below: 

1. Create a feature branch for a change
2. Create a pull request to merge the change into the main branch (this launches the `pull-req.yaml` workflow
3. The change would be merged, by pushing the feature branch to main (this launches the `push.yaml` workflow)

## Setup

Deploy a resource group, storage account and container, by uploading and executing the powershell script; `./storage-acc-deploy.ps1` in Azure Cloud Shell.

![creating-rg](https://user-images.githubusercontent.com/77082071/204031975-8684d54c-c812-4ac7-8824-4c1b7d7c9057.png)


GitHub actions is used in tandem with OIDC for a credential(less) setup. A federated identity app registration is created in  the Azure portal that authroises the GitHub actions JWT, json web token, issued by GitHub's token service to authenticate to AAD, azure active directory. 

The service principal has the contributor role assigned to it on the scope of the subscription within which resources are to be deployed. In addition to having the `Storage Data Blow Owner role` assigned over the scope of the storage container created.

Federated identity created for push and pull requests to the main branch of this github repo in Azure. 

![federated-credential-in-Azure](https://user-images.githubusercontent.com/77082071/204031483-e15367c3-8064-4732-b486-6bf24859670c.png)

GitHub actions workflow secrets set in the repository: 

* `AZURE_CLIENT_ID` - Application ID of the service principal.
* `AZURE_SUBSCRIPTION_ID` - ID of Azure subscription within which resources are deployed.
* `AZURE_TENANT_ID` - tenant ID within which the service principal for this project exists.

* `CONTAINER_NAME` - Name of storage container; which will store terraform state.
* `RESOURCE_GROUP_NAME` - Name of resource group containing storage account and container storing terraform state.
* `STORAGE_ACCOUNT` - Name of storage account with container that will store terraform state.

You'll need to ensure the `microsoft.insights` resource provider is registered. Run the following command in Azure cloud shell: `az provider register --namespace 'Microsoft.Insights'`

## Fulfillment of tasks from [original lab]()

* Tasks 1 and 2 are deployed wholly by terraform. Reference the web app plan and app service deployed in `infra/web-app.tf`

***Insert image of deployed web app service and stading deployment slot***

* Task 3 & 4 - Terraform ensures that the stading deployment slot uses local git for code deployment. However, the deployment of the code has to be done manually. Including, setting the Local Git/FTPS credentials in the user scope and copying the git URI for the stagin deployment.

![copying-git-clone-url-task3](https://user-images.githubusercontent.com/77082071/204031609-b89ffceb-d0d5-4dff-b721-7c220bb15c49.png)


![set-users-scope-git-credentials-task3](https://user-images.githubusercontent.com/77082071/204031573-cf7df33c-6c97-44f6-b898-9f2c33fa7676.png)

* Task 4 deploying code to the staging deployment slot 

> Open an interactive powershell session in Azure cloud shell.

> clone the sample code: `git clone https://github.com/Azure-Samples/php-docs-hello-world`

> set the repo as the working dir: `Set-Location -Path $HOME/php-docs-hello-world/`

> add a new remote `git remote add [deployment_user_name] [git_clone_url]`

> push sample web app code to Azure web app staging deployment slot: `git push [deployment_user_name] master`

> enter username and password previously set if prompted to authenticate

![deploying code task 4](https://user-images.githubusercontent.com/77082071/204031419-8145e559-7c57-493f-a44e-fb0c5c11aa2a.png)

![successful-deployment-of-web-app-via-cloud-shell-task4](https://user-images.githubusercontent.com/77082071/204031688-8a3ca1fd-2cc3-4376-af49-3657c2780f74.png)

* Task 5 & 6 - manually swap the staging slots within the deployment section of the web app service plan in the Azure portal. Autoscaling is already configured

> Reference the command outputted in `terraform apply` deploy-infra job in `push.yaml` and past the invokation command in Azure cloud shell. The command will resemble something similar to the below:  
`while ($true) { Invoke-WebRequest -Uri az104-9a-rest-of-the-uri.azurewebsites.net }`

![infinite-loop-http-requests](https://user-images.githubusercontent.com/77082071/204031450-24d20344-b062-41e7-9bf4-74f8d41281d4.png)

> minimise cloud shell and navigate to the Process explorer tab under Monitoring in the web app. Instance count will have increased to 2 after refershing the web page.

![instance-count-increased](https://user-images.githubusercontent.com/77082071/204032313-0f54925e-e72f-47cb-bece-932543b78a2a.png)

> Open cloudshell and close the the loop: `CTRL + C`

## Clean up resources 

Navigate to the Azure portal, locate the resource group you've created for this project: `az104-9a-rg1`. Delete this resource group in addition to the resouce group containing the terraform state blob. Done :)

![deleting-resources](https://user-images.githubusercontent.com/77082071/204032973-1df4a64c-add6-4132-b290-f16a9e72e33f.png)

## Useful links

1. [How to set secrets in GitHub](https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-encrypted-secrets-for-your-repository-and-organization-for-github-codespaces)
2. [Configuring OpenID Connect in Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure) 
3. [AZ-104 - lab 9a source](https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator/blob/master/Instructions/Labs/LAB_09a-Implement_Web_Apps.md)
4. [Authorize access to Azure Blob Storage using Azure role assignment conditions](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-auth-abac)

### GitHub Actions workflow links: 

1. [Setup terraform CLI in GitHub actions workflow](https://github.com/hashicorp/setup-terraform)
2. [Running actions in another directory](https://stackoverflow.com/questions/58139175/running-actions-in-another-directory)
3. [Automate Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
4. [Workflow syntax for GitHub Actions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
5. [Automate Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
6. [Checkout V3 - GitHub action docs](https://github.com/actions/checkout)

### Terraform documentation

1. [Web app service slot resource (includes examples for web app service plan and web app service)](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_web_app_slot)
