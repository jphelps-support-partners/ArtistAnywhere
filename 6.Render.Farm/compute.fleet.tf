##################################################################################
# Compute Fleet (https://learn.microsoft.com/azure/azure-compute-fleet/overview) #
##################################################################################

variable computeFleets {
  type = list(object({
    enable = bool
    name   = string
    machine = object({
      namePrefix = string
      sizes = list(object({
        name = string
      }))
      priority = object({
        standard = object({
          allocationStrategy = string
          capacityTarget     = number
          capacityMinimum    = number
        })
        spot = object({
          allocationStrategy = string
          evictionPolicy     = string
          capacityTarget     = number
          capacityMinimum    = number
          capacityMaintain = object({
            enable = bool
          })
        })
      })
      image = object({
        resourceGroupName = string
        galleryName       = string
        definitionName    = string
        versionId         = string
        plan = object({
          publisher = string
          product   = string
          name      = string
        })
      })
    })
    network = object({
      subnetName = string
      acceleration = object({
        enable = bool
      })
      locationExtended = object({
        enable = bool
      })
    })
    adminLogin = object({
      userName     = string
      userPassword = string
      sshKeyPublic = string
    })
  }))
}

locals {
  computeFleets = [
    for computeFleet in var.computeFleets : merge(computeFleet, {
      resourceLocation = {
        regionName   = module.global.resourceLocation.extendedZone.enable ? module.global.resourceLocation.extendedZone.regionName : module.global.resourceLocation.regionName
        extendedZone = module.global.resourceLocation.extendedZone.enable ? module.global.resourceLocation.extendedZone.name : null
      }
      machine = merge(computeFleet.machine, {
        image = merge(computeFleet.machine.image, {
          plan = {
            publisher = try(data.terraform_remote_state.image.outputs.linuxPlan.publisher, computeFleet.machine.image.plan.publisher)
            product   = try(data.terraform_remote_state.image.outputs.linuxPlan.offer, computeFleet.machine.image.plan.product)
            name      = try(data.terraform_remote_state.image.outputs.linuxPlan.sku, computeFleet.machine.image.plan.name)
          }
        })
      })
      network = merge(computeFleet.network, {
        subnetId = "${computeFleet.network.locationExtended.enable ? data.azurerm_virtual_network.studio_extended.id : data.azurerm_virtual_network.studio_region.id}/subnets/${var.existingNetwork.enable ? var.existingNetwork.subnetName : computeFleet.network.subnetName}"
      })
      adminLogin = merge(computeFleet.adminLogin, {
        userName     = computeFleet.adminLogin.userName != "" ? computeFleet.adminLogin.userName : data.azurerm_key_vault_secret.admin_username.value
        userPassword = computeFleet.adminLogin.userPassword != "" ? computeFleet.adminLogin.userPassword : data.azurerm_key_vault_secret.admin_password.value
        sshKeyPublic = computeFleet.adminLogin.sshKeyPublic != "" ? computeFleet.adminLogin.sshKeyPublic : data.azurerm_key_vault_secret.ssh_key_public.value
      })
      activeDirectory = merge(var.activeDirectory, {
        adminUsername = var.activeDirectory.adminUsername != "" ? var.activeDirectory.adminUsername : data.azurerm_key_vault_secret.admin_username.value
        adminPassword = var.activeDirectory.adminPassword != "" ? var.activeDirectory.adminPassword : data.azurerm_key_vault_secret.admin_password.value
      })
    }) if computeFleet.enable
  ]
}

resource azapi_resource fleet {
  for_each = {
    for computeFleet in local.computeFleets : computeFleet.name => computeFleet
  }
  name      = each.value.name
  type      = "Microsoft.AzureFleet/fleets@2024-05-01-preview"
  parent_id = azurerm_resource_group.farm.id
  location  = azurerm_resource_group.farm.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  body = jsonencode({
    properties = {
      computeProfile = {
        baseVirtualMachineProfile = {
          storageProfile = {
            imageReference = {
              id = "/subscriptions/${data.azurerm_client_config.studio.subscription_id}/resourceGroups/${each.value.machine.image.resourceGroupName}/providers/Microsoft.Compute/galleries/${each.value.machine.image.galleryName}/images/${each.value.machine.image.definitionName}/versions/${each.value.machine.image.versionId}"
            }
          }
          osProfile = {
            computerNamePrefix = each.value.machine.namePrefix != "" ? each.value.machine.namePrefix : each.value.name
            adminUsername      = each.value.adminLogin.userName
            adminPassword      = each.value.adminLogin.userPassword
          }
          networkProfile = {
            #networkApiVersion = "2024-03-01"
            networkInterfaceConfigurations = [
              {
                name = "nic"
                properties = {
                  ipConfigurations = [
                    {
                      name = "ipconfig"
                      properties = {
                        subnet = {
                          id = each.value.network.subnetId
                        }
                      }
                    }
                  ]
                  enableAcceleratedNetworking = each.value.network.acceleration.enable
                }
              }
            ]
          }
        }
      }
      regularPriorityProfile = {
        allocationStrategy = each.value.machine.priority.standard.allocationStrategy
        minCapacity        = each.value.machine.priority.standard.capacityMinimum
        capacity           = each.value.machine.priority.standard.capacityTarget
      }
      spotPriorityProfile = {
        allocationStrategy = each.value.machine.priority.spot.allocationStrategy
        evictionPolicy     = each.value.machine.priority.spot.evictionPolicy
        capacity           = each.value.machine.priority.spot.capacityTarget
        maintain           = each.value.machine.priority.spot.capacityMaintain.enable
      }
      vmSizesProfile = each.value.machine.sizes
    }
  })
  schema_validation_enabled = false
}
