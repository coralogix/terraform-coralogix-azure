# EventHub Integration Example

This example demonstrates how to deploy the Coralogix EventHub integration using Terraform.

## Prerequisites

- Terraform >= 1.7.4
- Azure CLI installed and authenticated (`az login`)
- An existing Azure EventHub namespace and instance
- An existing Resource Group and Storage Account for the Function App
- A Coralogix account with a private key

## Usage

1. **Copy the example tfvars file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your values:**
   - Set your Azure subscription ID
   - Configure your Coralogix region and private key
   - Specify your EventHub details
   - Provide Function App resource group and storage account

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the plan:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

6. **Sync the function triggers:**
   After deployment, run the command shown in the `sync_trigger_command` output to activate the EventHub trigger.

## Important Notes

### Azure Provider v4.0 Requirements

This module requires Azure provider version ~> 4.0, which needs explicit `subscription_id` configuration:

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
```

### Region Naming Convention

The module uses new region naming convention:
- `EU1` - Ireland (formerly "Europe")
- `EU2` - Stockholm (formerly "Europe2")
- `US1` - Ohio (formerly "US")
- `US2` - Oregon (new)
- `AP1` - Mumbai (formerly "India")
- `AP2` - Singapore
- `AP3` - Jakarta (new)

### Function App Name

You can either:
- Leave `function_app_name` empty for auto-generated name: `coralogix-eventhub-func-{uniqueId}`
- Provide a custom name: `my-custom-function-name`

## Outputs

- `sync_trigger_command` - Command to sync EventHub triggers
- `region_check` - Information about resource deployment regions

## Clean Up

To remove all resources:

```bash
terraform destroy
```

## More Information

- [Module Documentation](../../modules/eventhub/README.md)
- [EventHub Function App GitHub](https://github.com/coralogix/coralogix-azure-serverless/tree/master/EventHub)
- [Coralogix Documentation](https://coralogix.com/docs/)

