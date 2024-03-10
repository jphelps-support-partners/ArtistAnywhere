########################################################################
# Cosmos DB (https://learn.microsoft.com/azure/cosmos-db/introduction) #
########################################################################

variable cosmosDB {
  type = object({
    offerType = string
    dataConsistency = object({
      policyLevel = string
      maxStaleness = object({
        intervalSeconds = number
        itemUpdateCount = number
      })
    })
    dataAnalytics = object({
      enable     = bool
      schemaType = string
      workspace = object({
        name = string
        authentication = object({
          azureADOnly = bool
        })
        storageAccount = object({
          name        = string
          type        = string
          redundancy  = string
          performance = string
        })
        doubleEncryption = object({
          enable  = bool
          keyName = string
        })
      })
    })
    aggregationPipeline = object({
      enable = bool
    })
    automaticFailover = object({
      enable = bool
    })
    multiRegionWrite = object({
      enable = bool
    })
    partitionMerge = object({
      enable = bool
    })
    serverless = object({
      enable = bool
    })
    doubleEncryption = object({
      enable  = bool
      keyName = string
    })
  })
}

data azuread_service_principal cosmos_db {
  display_name = "Azure Cosmos DB"
}

data azurerm_key_vault_key data_encryption {
  count        = var.cosmosDB.doubleEncryption.enable ? 1 : 0
  name         = var.cosmosDB.doubleEncryption.keyName != "" ? var.cosmosDB.doubleEncryption.keyName : module.global.keyVault.keyName.dataEncryption
  key_vault_id = data.azurerm_key_vault.studio.id
}

locals {
  cosmosAccounts = [
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.noSQL.account.name}"
      name = var.noSQL.enable ? var.noSQL.account.name : ""
      type = "sql"
    },
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.mongoDB.account.name}"
      name = var.mongoDB.enable ? var.mongoDB.account.name : ""
      type = "mongo"
    },
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosCassandra.account.name}"
      name = var.cosmosCassandra.enable ? var.cosmosCassandra.account.name : ""
      type = "cassandra"
    },
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.gremlin.account.name}"
      name = var.gremlin.enable ? var.gremlin.account.name : ""
      type = "gremlin"
    },
    {
      id = "${azurerm_resource_group.database.id}/providers/Microsoft.DocumentDB/databaseAccounts/${var.table.account.name}"
      name = var.table.enable ? var.table.account.name : ""
      type = "table"
    }
  ]
}

resource azurerm_role_assignment key_vault {
  count                = var.cosmosDB.doubleEncryption.enable ? 1 : 0
  role_definition_name = "Key Vault Crypto Service Encryption User" # https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-crypto-service-encryption-user
  principal_id         = data.azurerm_user_assigned_identity.studio.principal_id
  scope                = data.azurerm_key_vault.studio.id
}

resource azurerm_cosmosdb_account studio {
  for_each = {
    for cosmosAccount in local.cosmosAccounts : cosmosAccount.type => cosmosAccount if cosmosAccount.name != ""
  }
  name                            = each.value.name
  resource_group_name             = azurerm_resource_group.database.name
  location                        = azurerm_resource_group.database.location
  kind                            = each.value.type == "mongo" ? "MongoDB" : "GlobalDocumentDB"
  mongo_server_version            = each.value.type == "mongo" ? var.mongoDB.account.version : null
  offer_type                      = var.cosmosDB.offerType
  key_vault_key_id                = var.cosmosDB.doubleEncryption.enable ? data.azurerm_key_vault_key.data_encryption[0].versionless_id : null
  analytical_storage_enabled      = var.cosmosDB.dataAnalytics.enable
  partition_merge_enabled         = var.cosmosDB.partitionMerge.enable
  enable_multiple_write_locations = var.cosmosDB.multiRegionWrite.enable
  enable_automatic_failover       = var.cosmosDB.automaticFailover.enable
  ip_range_filter                 = "${jsondecode(data.http.client_address.response_body).ip},104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26" # Azure Portal
  default_identity_type           = "UserAssignedIdentity=${data.azurerm_user_assigned_identity.studio.id}"
  local_authentication_disabled   = each.value.type == "sql" ? !var.noSQL.account.accessKeys.enable : null
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  consistency_policy {
    consistency_level       = var.cosmosDB.dataConsistency.policyLevel
    max_staleness_prefix    = var.cosmosDB.dataConsistency.maxStaleness.itemUpdateCount
    max_interval_in_seconds = var.cosmosDB.dataConsistency.maxStaleness.intervalSeconds
  }
  dynamic geo_location {
    for_each = local.regionNames
    content {
      location          = geo_location.value
      failover_priority = index(local.regionNames, geo_location.value)
    }
  }
  dynamic analytical_storage {
    for_each = var.cosmosDB.dataAnalytics.enable ? [1] : []
    content {
      schema_type = var.cosmosDB.dataAnalytics.schemaType
    }
  }
  dynamic capabilities {
    for_each = var.cosmosDB.serverless.enable ? ["EnableServerless"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = var.cosmosDB.aggregationPipeline.enable ? ["EnableAggregationPipeline"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "mongo" ? ["EnableMongo", "EnableMongoRoleBasedAccessControl"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "cassandra" ? ["EnableCassandra"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "gremlin" ? ["EnableGremlin"] : []
    content {
      name = capabilities.value
    }
  }
  dynamic capabilities {
    for_each = each.value.type == "table" ? ["EnableTable"] : []
    content {
      name = capabilities.value
    }
  }
  depends_on = [
    azurerm_role_assignment.key_vault
  ]
}