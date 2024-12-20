resourceGroupName = "2138disney-rg-dev-westus3-20241119-02.JobScheduler" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#########################################################################
# Virtual Machines (https://learn.microsoft.com/azure/virtual-machines) #
#########################################################################

virtualMachines = [
  {
    enable = false
    name   = "LnxJobScheduler"
    size   = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      #resourceGroupName = "2138disney-rg-dev-westus3-20241119-02.Image"
      #galleryName       = "xstudio"
      #definitionName    = "Linux"
      #versionId         = "1.0.0"
      resourceGroupName = "RESOURCE GROUP OF IMAGE"
      galleryName       = "IMAGE NAME"
      definitionName    = "Linux"
      versionId         = "1.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      type        = "Linux"
      storageType = "Premium_LRS"
      cachingType = "ReadOnly"
      sizeGB      = 0
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
      staticIpAddress = ""
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.sh"
        parameters = {
          autoScale = {
            enable                   = true
            resourceGroupName        = "2138disney-rg-dev-westus3-20241119-02.Farm"
            jobSchedulerName         = "Deadline"
            computeFarmName          = "LnxFarmC"
            computeFarmNodeCountMax  = 100
            workerIdleDeleteSeconds  = 300
            jobWaitThresholdSeconds  = 60
            detectionIntervalSeconds = 60
          }
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = true
      }
    }
  },
  {
    enable = true
    name   = "WinJobScheduler"
    size   = "Standard_D8as_v5" # https://learn.microsoft.com/azure/virtual-machines/sizes
    image = {
      resourceGroupName = "RESOURCE NAME HERE"
      galleryName       = "IMAGE NAME HERE"
      definitionName    = "WinServer"
      versionId         = "1.0.0"
      plan = {
        publisher = ""
        product   = ""
        name      = ""
      }
    }
    osDisk = {
      type        = "Windows"
      storageType = "Premium_LRS"
      cachingType = "ReadOnly"
      sizeGB      = 0
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
      locationExtended = {
        enable = false
      }
      staticIpAddress = "10.0.127.0"
    }
    extension = {
      custom = {
        enable   = true
        name     = "Initialize"
        fileName = "initialize.ps1"
        parameters = {
          autoScale = {
            enable                   = true
            resourceGroupName        = "2138disney-rg-dev-westus3-20241119-02.Farm"
            jobSchedulerName         = "Deadline"
            computeFarmName          = "WinFarmC"
            computeFarmNodeCountMax  = 100
            workerIdleDeleteSeconds  = 300
            jobWaitThresholdSeconds  = 60
            detectionIntervalSeconds = 60
          }
        }
      }
      monitor = {
        enable = false
        name   = "Monitor"
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshKeyPublic = ""
      passwordAuth = {
        disable = false
      }
    }
  }
]

############################################################################
# Private DNS (https://learn.microsoft.com/azure/dns/private-dns-overview) #
############################################################################

dnsRecord = {
  name        = "job"
  ttlSeconds  = 300
}

#################################################################################################################################################
# Active Directory (https://learn.microsoft.com/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview) #
#################################################################################################################################################

activeDirectory = {
  enable     = true
  domainName = "azure.studio"
}

##################################################
# Pre-Existing Resource Dependency Configuration #
##################################################

existingNetwork = {
  enable            = false
  name              = ""
  subnetName        = ""
  resourceGroupName = ""
  privateDns = {
    zoneName          = ""
    resourceGroupName = ""
  }
}
