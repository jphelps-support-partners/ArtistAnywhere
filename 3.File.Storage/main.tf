terraform {
  required_version = ">=1.9.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.10.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~>2.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~>2.0.0"
    }
  }
  backend azurerm {
    key              = "3.File.Storage"
    use_azuread_auth = true
  }
}

provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    managed_disk {
      expand_without_downtime = true
    }
    virtual_machine {
      delete_os_disk_on_deletion            = true
      detach_implicit_data_disk_on_deletion = false
      skip_shutdown_and_force_delete        = false
      graceful_shutdown                     = false
    }
    virtual_machine_scale_set {
      reimage_on_manual_upgrade     = true
      roll_instances_when_required  = true
      scale_to_zero_before_deletion = true
      force_delete                  = false
    }
  }
  subscription_id     = module.global.subscriptionId
  storage_use_azuread = true
}

module global {
  source = "../0.Global.Foundation/cfg"
}

variable resourceGroupName {
  type = string
}

variable regionName {
  type = string
}

data http client_address {
  url = "https://api.ipify.org?format=json"
}

data azurerm_client_config studio {}

data azurerm_user_assigned_identity studio {
  name                = module.global.managedIdentity.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault studio {
  name                = module.global.keyVault.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_key_vault_secret admin_username {
  name         = module.global.keyVault.secretName.adminUsername
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret admin_password {
  name         = module.global.keyVault.secretName.adminPassword
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret ssh_key_public {
  name         = module.global.keyVault.secretName.sshKeyPublic
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_secret ssh_key_private {
  name         = module.global.keyVault.secretName.sshKeyPrivate
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_key_vault_key data_encryption {
  name         = module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio.id
}

data azurerm_log_analytics_workspace studio {
  name                = module.global.monitor.name
  resource_group_name = data.terraform_remote_state.global.outputs.monitor.resourceGroupName
}

data azurerm_app_configuration studio {
  name                = module.global.appConfig.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_app_configuration_keys studio {
  configuration_store_id = data.azurerm_app_configuration.studio.id
}

data terraform_remote_state global {
  backend = "local"
  config = {
    path = "../0.Global.Foundation/terraform.tfstate"
  }
}

data terraform_remote_state network {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "1.Virtual.Network"
    use_azuread_auth     = true
  }
}

data terraform_remote_state image {
  backend = "azurerm"
  config = {
    resource_group_name  = module.global.resourceGroupName
    storage_account_name = module.global.storage.accountName
    container_name       = module.global.storage.containerName.terraformState
    key                  = "2.Image.Builder"
    use_azuread_auth     = true
  }
}

data azurerm_resource_group dns {
  name = data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

data azurerm_virtual_network studio_region {
  name                = data.terraform_remote_state.network.outputs.virtualNetworks[0].name
  resource_group_name = var.regionName != "" ? "${data.azurerm_resource_group.dns.name}.${var.regionName}" : data.terraform_remote_state.network.outputs.virtualNetworks[0].resourceGroupName
}

data azurerm_virtual_network studio_extended {
  name                = reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].name
  resource_group_name = reverse(data.terraform_remote_state.network.outputs.virtualNetworks)[0].resourceGroupName
}

data azurerm_private_dns_zone studio {
  name                = data.terraform_remote_state.network.outputs.privateDns.zoneName
  resource_group_name = data.terraform_remote_state.network.outputs.privateDns.resourceGroupName
}

data azurerm_subnet storage_region {
  name                 = "Storage"
  resource_group_name  = data.azurerm_virtual_network.studio_region.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.studio_region.name
}

# data azurerm_subnet storage_extended {
#   name                 = "Storage"
#   resource_group_name  = data.azurerm_virtual_network.studio_extended.resource_group_name
#   virtual_network_name = data.azurerm_virtual_network.studio_extended.name
# }

locals {
  regionName = var.regionName != "" ? var.regionName : module.global.resourceLocation.regionName
  nfsStorageAccounts = [
    for storageAccount in local.storageAccounts : storageAccount if storageAccount.enableBlobNfsV3 == true || storageAccount.type == "FileStorage"
  ]
}

resource azurerm_resource_group storage {
  count    = length(local.storageAccounts) > 0 ? 1 : 0
  name     = var.resourceGroupName
  location = local.regionName
  tags = {
    AAA = basename(path.cwd)
    Owner = "john.phelps@support-partners.com"
  }
}

output nfsStorageAccount {
  value = length(local.nfsStorageAccounts) > 0 ? {
    name              = local.nfsStorageAccounts[0].name
    resourceGroupName = local.nfsStorageAccounts[0].resourceGroupName
  } : null
  sensitive = true
}
