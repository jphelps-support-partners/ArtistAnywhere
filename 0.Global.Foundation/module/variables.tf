variable regionName {
  default = "WestUS3" # Set Azure region name from "az account list-locations --query [].name"
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
    enable = true
    name   = "xstudio" # Set to a globally unique name (alphanumeric, hyphens)
    secretName = {
      adminUsername     = "AdminUsername"
      adminPassword     = "AdminPassword"
      databaseUsername  = "DatabaseUsername"
      databasePassword  = "DatabasePassword"
      gatewayConnection = "GatewayConnection"
    }
    keyName = {
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
    name = "xstudio"
    agentVersion = {
      linux   = "1.29"
      windows = "1.22"
    }
  }
}

output regionName {
  value = var.regionName
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
