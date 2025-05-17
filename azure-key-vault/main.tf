terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Key Vault."
}

variable "location" {
  type        = string
  description = "The Azure region where the Key Vault will be created."
  default     = "East US"
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Azure Key Vault. Must be globally unique."
}

variable "sku_name" {
  type        = string
  description = "The SKU name of the Key Vault. Allowed values are 'standard' or 'premium'."
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "tenant_id" {
  type        = string
  description = "The Azure Tenant ID where the Key Vault will be created. This is usually the tenant of the service principal or user running Terraform."
}

variable "enabled_for_deployment" {
  type        = bool
  description = "Specifies if the Key Vault is enabled for deployment of VMs."
  default     = true
}

variable "enabled_for_disk_encryption" {
  type        = bool
  description = "Specifies if the Key Vault is enabled for disk encryption."
  default     = true
}

variable "enabled_for_template_deployment" {
  type        = bool
  description = "Specifies if the Key Vault is enabled for template deployment."
  default     = true
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_key_vault" "kv" {
  name                            = var.key_vault_name
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  tenant_id                       = var.tenant_id
  sku_name                        = var.sku_name

  // Default access policy - allows the current user/SP to manage keys, secrets, certificates
  // In a real scenario, you'd configure specific access policies
  access_policy {
    tenant_id = var.tenant_id
    object_id = provider.azurerm.skip_provider_registration == true ? null : data.azurerm_client_config.current.object_id // Simplified for example

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Recover", "Backup", "Restore", "Purge"
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Recover", "Backup", "Restore", "Purge", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
    ]
  }

  tags = {
    environment = "Terraform Catalog"
    createdBy   = "CloudHub"
  }
}

// Data source to get the current client's object ID for the default access policy
// This might require the user/SP running Terraform to have directory read permissions
data "azurerm_client_config" "current" {}

output "key_vault_id" {
  value       = azurerm_key_vault.kv.id
  description = "The ID of the created Key Vault."
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "The URI of the created Key Vault."
}
