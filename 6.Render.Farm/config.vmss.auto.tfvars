######################################################################################################
# Virtual Machine Scale Sets (https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) #
######################################################################################################

virtualMachineScaleSets = [
  {
    enable = false
    name   = "LnxFarmC"
    machine = {
      namePrefix = ""
      size       = "Standard_HB120rs_v3"
      count      = 2
      image = {
        id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/2.0.0"
        plan = {
          enable    = false
          publisher = ""
          product   = ""
          name      = ""
        }
      }
    }
    operatingSystem = {
      type = "Linux"
      disk = {
        storageType = "Standard_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
          placement = "ResourceDisk"
        }
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {
        enable  = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        timeout = "PT1H"
      }
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
        fileName = "initialize.sh"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        protocol    = "tcp"
        port        = 111
        requestPath = ""
      }
      monitor = {
        enable = false
      }
    }
    flexibleOrchestration = {
      enable           = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      faultDomainCount = 1     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-fault-domains
    }
  },
  {
    enable = false
    name   = "LnxFarmG"
    machine = {
      namePrefix = ""
      size       = "Standard_NV36ads_A10_v5"
      count      = 2
      image = {
        id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/Linux/versions/2.1.0"
        plan = {
          enable    = false
          publisher = ""
          product   = ""
          name      = ""
        }
      }
    }
    operatingSystem = {
      type = "Linux"
      disk = {
        storageType = "Standard_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
          placement = "ResourceDisk"
        }
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {
        enable  = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        timeout = "PT1H"
      }
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
        fileName = "initialize.sh"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        protocol    = "tcp"
        port        = 111
        requestPath = ""
      }
      monitor = {
        enable = false
      }
    }
    flexibleOrchestration = {
      enable           = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      faultDomainCount = 1     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-fault-domains
    }
  },
  {
    enable = false
    name   = "WinFarmC"
    machine = {
      namePrefix = ""
      size       = "Standard_HB120rs_v3"
      count      = 2
      image = {
        id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinFarm/versions/2.0.0"
        plan = {
          enable    = false
          publisher = ""
          product   = ""
          name      = ""
        }
      }
    }
    operatingSystem = {
      type = "Windows"
      disk = {
        storageType = "Standard_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
          placement = "ResourceDisk"
        }
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {
        enable  = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        timeout = "PT1H"
      }
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
        fileName = "initialize.ps1"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        protocol    = "tcp"
        port        = 445
        requestPath = ""
      }
      monitor = {
        enable = false
      }
    }
    flexibleOrchestration = {
      enable           = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      faultDomainCount = 1     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-fault-domains
    }
  },
  {
    enable = false
    name   = "WinFarmG"
    machine = {
      namePrefix = ""
      size       = "Standard_NV36ads_A10_v5"
      count      = 2
      image = {
        id = "/subscriptions/5cc0d8f1-3643-410c-8646-1a2961134bd3/resourceGroups/ArtistAnywhere.Image/providers/Microsoft.Compute/galleries/xstudio/images/WinFarm/versions/2.1.0"
        plan = {
          enable    = false
          publisher = ""
          product   = ""
          name      = ""
        }
      }
    }
    operatingSystem = {
      type = "Windows"
      disk = {
        storageType = "Standard_LRS"
        cachingType = "ReadOnly"
        sizeGB      = 0
        ephemeral = { # https://learn.microsoft.com/azure/virtual-machines/ephemeral-os-disks
          enable    = true
          placement = "ResourceDisk"
        }
      }
    }
    spot = {
      enable         = true     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot
      evictionPolicy = "Delete" # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#eviction-policy
      tryRestore = {
        enable  = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/use-spot#try--restore
        timeout = "PT1H"
      }
    }
    network = {
      subnetName = "Farm"
      acceleration = { # https://learn.microsoft.com/azure/virtual-network/accelerated-networking-overview
        enable = true
      }
    }
    adminLogin = {
      userName     = ""
      userPassword = ""
      sshPublicKey = "" # "ssh-rsa ..."
      passwordAuth = {
        disable = false
      }
    }
    extension = {
      initialize = {
        enable   = true
        fileName = "initialize.ps1"
        parameters = {
          terminateNotification = { # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification
            enable       = false
            delayTimeout = "PT5M"
          }
        }
      }
      health = {
        enable      = true
        protocol    = "tcp"
        port        = 445
        requestPath = ""
      }
      monitor = {
        enable = false
      }
    }
    flexibleOrchestration = {
      enable           = false # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-orchestration-modes
      faultDomainCount = 1     # https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-fault-domains
    }
  }
]