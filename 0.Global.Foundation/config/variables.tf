variable resourceLocation {
  default = {
    region   = "WestUS"
    edgeZone = "LosAngeles"
  }
}

variable resourceGroupName {
  default = "ArtistAnywhere" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed
}

###################################################################################
# Storage (https://learn.microsoft.com/azure/storage/common/storage-introduction) #
###################################################################################

variable rootStorage {
  default = {
    accountName = "xstudio0" # Set to a globally unique name (lowercase alphanumeric)
    containerName = {
      terraformState = "terraform-state"
    }
  }
}

#####################################################################################################################
# Managed Identity (https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview) #
#####################################################################################################################

variable managedIdentity {
  default = {
    name = "xstudio" # Alphanumeric, underscores and hyphens are allowed
  }
}

############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

variable keyVault {
  default = {
    enable = false
    name   = "xstudio" # Set to a globally unique name (alphanumeric, hyphens)
    secretName = {
      adminUsername     = "AdminUsername"
      adminPassword     = "AdminPassword"
      databaseUsername  = "DatabaseUsername"
      databasePassword  = "DatabasePassword"
      gatewayConnection = "GatewayConnection"
    }
    keyName = {
      dataEncryption  = "DataEncryption"
      cacheEncryption = "CacheEncryption"
    }
    certificateName = {
    }
  }
}

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

variable monitor {
  default = {
    enable = true
    name   = "xstudio"
    agentVersion = {
      linux   = "1.30"
      windows = "1.24"
    }
  }
}

output resourceLocation {
  value = var.resourceLocation
}

output resourceGroupName {
  value = var.resourceGroupName
}

output rootStorage {
  value = var.rootStorage
}

output managedIdentity {
  value = var.managedIdentity
}

output keyVault {
  value = var.keyVault
}

output monitor {
  value = var.monitor
}
