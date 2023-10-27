############################################################################
# Batch (https://learn.microsoft.com/azure/batch/batch-technical-overview) #
############################################################################

variable batch {
  type = object({
    enable = bool
    account = object({
      name = string
      storage = object({
        accountName       = string
        resourceGroupName = string
      })
    })
    pools = list(object({
      enable      = bool
      name        = string
      displayName = string
      node = object({
        imageId = string
        agentId = string
        machine = object({
          size  = string
          count = number
        })
        osDisk = object({
          ephemeral = object({
            enable = bool
          })
        })
        placementPolicy    = string
        deallocationMode   = string
        maxConcurrentTasks = number
      })
      fillMode = object({
        nodePack = object({
          enable = bool
        })
      })
      spot = object({
        enable = bool
      })
    }))
  })
  validation {
    condition     = alltrue([ for pool in var.batch.pools : !(pool.node.osDisk.ephemeral.enable && pool.spot.enable) if var.batch.enable && pool.enable ])
    error_message = "Ephemeral OS disks cannot be used in conjunction with Spot VMs in Batch pools due to the service managed eviction policy."
  }
}

data azuread_service_principal batch {
  count        = var.batch.enable ? 1 : 0
  display_name = "Microsoft Azure Batch"
}

data azurerm_key_vault batch {
  count               = module.global.keyVault.enable ? 1 : 0
  name                = "${module.global.keyVault.name}-batch"
  resource_group_name = module.global.resourceGroupName
}

locals {
  fileSystemsLinuxBatch = [
    for fileSystem in local.fileSystemsLinux : fileSystem if !fileSystem.iaasOnly
  ]
  fileSystemsWindowsBatch = [
    for fileSystem in local.fileSystemsWindows : fileSystem if !fileSystem.iaasOnly
  ]
}

###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_dns_zone batch {
  count               = var.batch.enable ? 1 : 0
  name                = "privatelink.batch.azure.com"
  resource_group_name = azurerm_resource_group.farm.name
}

resource azurerm_private_dns_zone_virtual_network_link batch {
  count                 = var.batch.enable ? 1 : 0
  name                  = "batch-${lower(data.azurerm_virtual_network.studio.location)}"
  resource_group_name   = azurerm_resource_group.farm.name
  private_dns_zone_name = azurerm_private_dns_zone.batch[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint batch_account {
  count               = var.batch.enable ? 1 : 0
  name                = "${azurerm_batch_account.scheduler[0].name}-batchAccount"
  resource_group_name = azurerm_resource_group.farm.name
  location            = azurerm_resource_group.farm.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_batch_account.scheduler[0].name
    private_connection_resource_id = azurerm_batch_account.scheduler[0].id
    is_manual_connection           = false
    subresource_names = [
      "batchAccount"
    ]
  }
  private_dns_zone_group {
    name = azurerm_batch_account.scheduler[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.batch[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.batch
  ]
}

resource azurerm_private_endpoint batch_node {
  count               = var.batch.enable ? 1 : 0
  name                = "${azurerm_batch_account.scheduler[0].name}-batchNode"
  resource_group_name = azurerm_resource_group.farm.name
  location            = azurerm_resource_group.farm.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_batch_account.scheduler[0].name
    private_connection_resource_id = azurerm_batch_account.scheduler[0].id
    is_manual_connection           = false
    subresource_names = [
      "nodeManagement"
    ]
  }
  private_dns_zone_group {
    name = azurerm_batch_account.scheduler[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.batch[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.batch
  ]
}

############################################################################
# Batch (https://learn.microsoft.com/azure/batch/batch-technical-overview) #
############################################################################

resource azurerm_role_assignment batch {
  count                = var.batch.enable ? 1 : 0
  role_definition_name = "Contributor" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#contributor
  principal_id         = data.azuread_service_principal.batch[0].object_id
  scope                = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}"
}

resource azurerm_batch_account scheduler {
  count                = var.batch.enable ? 1 : 0
  name                 = var.batch.account.name
  resource_group_name  = azurerm_resource_group.farm.name
  location             = azurerm_resource_group.farm.location
  pool_allocation_mode = "UserSubscription"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_profile {
    account_access {
      default_action = "Deny"
      ip_rule {
        action   = "Allow"
        ip_range = jsondecode(data.http.client_address.response_body).ip
      }
    }
    node_management_access {
      default_action = "Deny"
      ip_rule {
        action   = "Allow"
        ip_range = jsondecode(data.http.client_address.response_body).ip
      }
    }
  }
  key_vault_reference {
    id  = data.azurerm_key_vault.batch[0].id
    url = data.azurerm_key_vault.batch[0].vault_uri
  }
  storage_account_id                  = data.azurerm_storage_account.studio.id
  storage_account_node_identity       = data.azurerm_user_assigned_identity.studio.id
  storage_account_authentication_mode = "BatchAccountManagedIdentity"
  depends_on = [
    azurerm_role_assignment.batch
  ]
}

resource azurerm_batch_pool farm {
  for_each = {
    for pool in var.batch.pools : pool.name => pool if var.batch.enable && pool.enable
  }
  name                     = each.value.name
  display_name             = each.value.displayName != "" ? each.value.displayName : each.value.name
  resource_group_name      = azurerm_resource_group.farm.name
  account_name             = azurerm_batch_account.scheduler[0].name
  node_agent_sku_id        = each.value.node.agentId
  vm_size                  = each.value.node.machine.size
  max_tasks_per_node       = each.value.node.maxConcurrentTasks
  os_disk_placement        = each.value.node.osDisk.ephemeral.enable ? "CacheDisk" : null
  inter_node_communication = "Disabled"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  storage_image_reference {
    id = each.value.node.imageId
  }
  network_configuration {
    subnet_id = data.azurerm_subnet.farm.id
  }
  node_placement {
    policy = each.value.node.placementPolicy
  }
  task_scheduling_policy {
    node_fill_type = each.value.fillMode.nodePack.enable ? "Pack" : "Spread"
  }
  fixed_scale {
    node_deallocation_method  = each.value.node.deallocationMode
    target_low_priority_nodes = each.value.spot.enable ? each.value.node.machine.count : 0
    target_dedicated_nodes    = each.value.spot.enable ? 0 : each.value.node.machine.count
  }
  # dynamic mount {
  #   for_each = length(local.fileSystemsLinuxBatch) > 0 || length(local.fileSystemsWindowsBatch) > 0 ? [1] : []
  #   content {
  #     dynamic nfs_mount {
  #       for_each = strcontains(each.value.node.agentId, "linux") ? local.fileSystemsLinuxBatch : []
  #       content {
  #         relative_mount_path = each.value.path
  #         source              = each.value.source
  #         mount_options       = each.value.options
  #       }
  #     }
  #     dynamic nfs_mount {
  #       for_each = strcontains(each.value.node.agentId, "windows") ? local.fileSystemsWindowsBatch : []
  #       content {
  #         relative_mount_path = each.value.path
  #         source              = each.value.source
  #         mount_options       = each.value.options
  #       }
  #     }
  #   }
  # }
  # dynamic start_task {
  #   for_each = var.activeDirectory.enable && strcontains(each.value.node.agentId, "windows") ? [1] : []
  #   content {
  #     command_line = ""
  #     user_identity {
  #     }
  #   }
  # }
}

output batchAccount {
  value = {
    enable   = var.batch.enable
    endpoint = var.batch.enable ? azurerm_batch_account.scheduler[0].account_endpoint : ""
  }
}
