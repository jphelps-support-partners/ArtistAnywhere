variable subscriptionId {
  # default = "" # Set to your Azure subscription id
  default = "99dce0fa-8b59-4c2f-9feb-74ff0d409de0" # Set to your Azure subscription id
}

variable resourceLocation {
  default = {
    regionName = "WestUS3" # Set from "az account list-locations --query [].name"
    extendedZone = {
      enable     = false
      name       = "LosAngeles"
      regionName = "WestUS"
    }
  }
}

variable resourceGroupName {
  default = "2138disney-rg-dev-westus3-20241109-02" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed
}

#############################################################################################################
# Managed Identity (https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) #
#############################################################################################################

variable managedIdentity {
  default = {
    name = "dis2138id20241119" # Alphanumeric, underscores and hyphens are allowed
  }
}

###################################################################################
# Storage (https://learn.microsoft.com/azure/storage/common/storage-introduction) #
###################################################################################

variable storage {
  default = {
    accountName = "dis2138stor20241119" # Set to a globally unique name (lowercase alphanumeric)
    containerName = {
      terraformState = "terraform-state"
    }
  }
}

############################################################################
# Key Vault (https://learn.microsoft.com/azure/key-vault/general/overview) #
############################################################################

variable keyVault {
  default = {
    name = "dis2138key20241119" # Set to a globally unique name (alphanumeric, hyphens)
    secretName = {
      sshKeyPublic      = "SSHKeyPublic"
      sshKeyPrivate     = "SSHKeyPrivate"
      adminUsername     = "AdminUsername"
      adminPassword     = "AdminPassword"
      serviceUsername   = "ServiceUsername"
      servicePassword   = "ServicePassword"
      gatewayConnection = "GatewayConnection"
    }
    keyName = {
      dataEncryption = "DataEncryption"
    }
    certificateName = {
    }
  }
}

##########################################################################################
# App Configuration (https://learn.microsoft.com/azure/azure-app-configuration/overview) #
##########################################################################################

variable appConfig {
  default = {
    name = "dis2138app20241119"
    key = {
      nvidiaCUDAVersion           = "NVIDIA/CUDA/Version"
      nvidiaOptiXVersion          = "NVIDIA/OptiX/Version"
      azBlobNFSMountVersion       = "Azure/Blob/NFSMount/Version"
      hpAnywareAgentVersion       = "HP/Anyware/Agent/Version"
      jobSchedulerDeadlineVersion = "Job/Scheduler/Deadline/Version"
      jobSchedulerLSFVersion      = "Job/Scheduler/LSF/Version"
      jobProcessorPBRTVersion     = "Job/Processor/PBRT/Version"
      jobProcessorBlenderVersion  = "Job/Processor/Blender/Version"
      monitorAgentLinuxVersion    = "Monitor/Agent/Linux/Version"
      monitorAgentWindowsVersion  = "Monitor/Agent/Windows/Version"
    }
  }
}

######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

variable monitor {
  default = {
    name = "dis2138mon20241119"
  }
}

###################################################################################################
# Defender (https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction) #
###################################################################################################

variable defender {
  default = {
    storage = {
      malwareScanning = {
        enable        = true
        maxPerMonthGB = 5000
      }
      sensitiveDataDiscovery = {
        enable = true
      }
    }
  }
}

output subscriptionId {
  value = var.subscriptionId
}

output resourceLocation {
  value = var.resourceLocation
}

output resourceGroupName {
  value = var.resourceGroupName
}

output managedIdentity {
  value = var.managedIdentity
}

output storage {
  value = var.storage
}

output keyVault {
  value = var.keyVault
}

output appConfig {
  value = var.appConfig
}

output monitor {
  value = var.monitor
}

output defender {
  value = var.defender
}
