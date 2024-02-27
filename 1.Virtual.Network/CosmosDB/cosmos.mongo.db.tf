#########################################################################################
# Cosmos DB Mongo DB (https://learn.microsoft.com/azure/cosmos-db/mongodb/introduction) #
#########################################################################################

variable cosmosMongoDB {
  type = object({
    enable  = bool
    account = object({
      name    = string
      version = string
    })
    database = object({
      enable     = bool
      name       = string
      throughput = number
    })
  })
}

variable cosmosMongoDBvCore {
  type = object({
    enable = bool
    cluster = object({
      name    = string
      tier    = string
      version = string
    })
    node = object({
      count      = number
      diskSizeGB = number
    })
    highAvailability = object({
      enable = bool
    })
  })
}

###############################################################################################
# Cosmos DB Mongo DB RU (https://learn.microsoft.com/azure/cosmos-db/mongodb/ru/introduction) #
###############################################################################################

resource azurerm_private_dns_zone mongo_db {
  count               = var.cosmosMongoDB.enable ? 1 : 0
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.database.name
}

resource azurerm_private_dns_zone_virtual_network_link mongo_db {
  count                 = var.cosmosMongoDB.enable ? 1 : 0
  name                  = "mongo"
  resource_group_name   = azurerm_resource_group.database.name
  private_dns_zone_name = azurerm_private_dns_zone.mongo_db[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint mongo_db {
  count               = var.cosmosMongoDB.enable ? 1 : 0
  name                = azurerm_cosmosdb_account.studio["mongo"].name
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azurerm_cosmosdb_account.studio["mongo"].name
    private_connection_resource_id = azurerm_cosmosdb_account.studio["mongo"].id
    is_manual_connection           = false
    subresource_names = [
      "MongoDB"
    ]
  }
  private_dns_zone_group {
    name = azurerm_cosmosdb_account.studio["mongo"].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.mongo_db[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mongo_db
  ]
}

resource azurerm_cosmosdb_mongo_database mongo_db {
  count               = var.cosmosMongoDB.enable && var.cosmosMongoDB.database.enable ? 1 : 0
  name                = var.cosmosMongoDB.database.name
  resource_group_name = azurerm_cosmosdb_account.studio["mongo"].resource_group_name
  account_name        = azurerm_cosmosdb_account.studio["mongo"].name
  throughput          = var.cosmosMongoDB.database.throughput
}

#####################################################################################################
# Cosmos DB Mongo DB vCore (https://learn.microsoft.com/azure/cosmos-db/mongodb/vcore/introduction) #
#####################################################################################################

resource azurerm_private_dns_zone mongo_cluster {
  count               = var.cosmosMongoDBvCore.enable ? 1 : 0
  name                = "privatelink.mongocluster.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.database.name
}

resource azurerm_private_dns_zone_virtual_network_link mongo_cluster {
  count                 = var.cosmosMongoDBvCore.enable ? 1 : 0
  name                  = "mongo-cluster"
  resource_group_name   = azurerm_resource_group.database.name
  private_dns_zone_name = azurerm_private_dns_zone.mongo_cluster[0].name
  virtual_network_id    = data.azurerm_virtual_network.studio.id
}

resource azurerm_private_endpoint mongo_cluster {
  count               = var.cosmosMongoDBvCore.enable ? 1 : 0
  name                = "${azapi_resource.mongo_cluster[0].name}-${azurerm_private_dns_zone_virtual_network_link.mongo_cluster[0].name}"
  resource_group_name = azurerm_resource_group.database.name
  location            = azurerm_resource_group.database.location
  subnet_id           = data.azurerm_subnet.farm.id
  private_service_connection {
    name                           = azapi_resource.mongo_cluster[0].name
    private_connection_resource_id = azapi_resource.mongo_cluster[0].id
    is_manual_connection           = false
    subresource_names = [
      "MongoCluster"
    ]
  }
  private_dns_zone_group {
    name = azapi_resource.mongo_cluster[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.mongo_cluster[0].id
    ]
  }
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mongo_cluster
  ]
}

resource azapi_resource mongo_cluster {
  count     = var.cosmosMongoDBvCore.enable ? 1 : 0
  name      = var.cosmosMongoDBvCore.cluster.name
  type      = "Microsoft.DocumentDB/mongoClusters@2024-02-15-preview"
  parent_id = azurerm_resource_group.database.id
  location  = azurerm_resource_group.database.location
  body = jsonencode({
    properties = {
      nodeGroupSpecs = [
        {
          kind       = "Shard"
          sku        = var.cosmosMongoDBvCore.cluster.tier
          nodeCount  = var.cosmosMongoDBvCore.node.count
          diskSizeGB = var.cosmosMongoDBvCore.node.diskSizeGB
          enableHa   = var.cosmosMongoDBvCore.highAvailability.enable
        }
      ]
      serverVersion              = var.cosmosMongoDBvCore.cluster.version
      administratorLogin         = data.azurerm_key_vault_secret.admin_username.value
      administratorLoginPassword = data.azurerm_key_vault_secret.admin_password.value
    }
  })
  schema_validation_enabled = false
}
