###############################################################################################
# Private Endpoint (https://learn.microsoft.com/azure/private-link/private-endpoint-overview) #
###############################################################################################

resource azurerm_private_endpoint storage_blob {
  name                = "${lower(data.azurerm_storage_account.studio.name)}-blob"
  resource_group_name = data.azurerm_storage_account.studio.resource_group_name
  location            = data.azurerm_storage_account.studio.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_storage_account.studio.name
    private_connection_resource_id = data.azurerm_storage_account.studio.id
    is_manual_connection           = false
    subresource_names = [
      "blob"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.storage_blob.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_blob.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_subnet_nat_gateway_association.studio
 ]
}

resource azurerm_private_endpoint storage_file {
  name                = "${lower(data.azurerm_storage_account.studio.name)}-file"
  resource_group_name = data.azurerm_storage_account.studio.resource_group_name
  location            = data.azurerm_storage_account.studio.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_storage_account.studio.name
    private_connection_resource_id = data.azurerm_storage_account.studio.id
    is_manual_connection           = false
    subresource_names = [
      "file"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.storage_file.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.storage_file.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_endpoint.storage_blob
  ]
}

resource azurerm_private_endpoint key_vault {
  name                = "${lower(data.azurerm_key_vault.studio.name)}-key-vault"
  resource_group_name = data.azurerm_key_vault.studio.resource_group_name
  location            = data.azurerm_key_vault.studio.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_key_vault.studio.name
    private_connection_resource_id = data.azurerm_key_vault.studio.id
    is_manual_connection           = false
    subresource_names = [
      "vault"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.key_vault.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.key_vault.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_endpoint.storage_file
  ]
}

resource azurerm_private_endpoint app_config {
  name                = "${lower(data.azurerm_app_configuration.studio.name)}-app-config"
  resource_group_name = data.azurerm_app_configuration.studio.resource_group_name
  location            = data.azurerm_app_configuration.studio.location
  subnet_id           = "${local.virtualNetwork.id}/subnets/Storage"
  private_service_connection {
    name                           = data.azurerm_app_configuration.studio.name
    private_connection_resource_id = data.azurerm_app_configuration.studio.id
    is_manual_connection           = false
    subresource_names = [
      "configurationStores"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.app_config.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.app_config.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_endpoint.key_vault
 ]
}

resource azurerm_private_endpoint container_registry {
  count               = data.terraform_remote_state.global.outputs.containerRegistry.enable ? 1 : 0
  name                = "${lower(data.terraform_remote_state.global.outputs.containerRegistry.name)}-${azurerm_private_dns_zone_virtual_network_link.container_registry[0].name}"
  resource_group_name = data.terraform_remote_state.global.outputs.containerRegistry.resourceGroupName
  location            = data.terraform_remote_state.global.outputs.containerRegistry.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/Farm"
  private_service_connection {
    name                           = data.terraform_remote_state.global.outputs.containerRegistry.name
    private_connection_resource_id = data.terraform_remote_state.global.outputs.containerRegistry.id
    is_manual_connection           = false
    subresource_names = [
      "registry"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.container_registry[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.container_registry[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_services_open {
  count               = data.terraform_remote_state.global.outputs.ai.services.enable ? 1 : 0
  name                = "${lower(data.terraform_remote_state.global.outputs.ai.services.name)}-${azurerm_private_dns_zone_virtual_network_link.ai_services_open[0].name}"
  resource_group_name = data.terraform_remote_state.global.outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.global.outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.global.outputs.ai.services.name
    private_connection_resource_id = data.terraform_remote_state.global.outputs.ai.services.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_services_open[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_services_open[0].id
    ]
  }
}

resource azurerm_private_endpoint ai_services_cognitive {
  count               = data.terraform_remote_state.global.outputs.ai.services.enable ? 1 : 0
  name                = "${lower(data.terraform_remote_state.global.outputs.ai.services.name)}-${azurerm_private_dns_zone_virtual_network_link.ai_services_cognitive[0].name}"
  resource_group_name = data.terraform_remote_state.global.outputs.ai.resourceGroupName
  location            = data.terraform_remote_state.global.outputs.ai.regionName
  subnet_id           = "${local.virtualNetwork.id}/subnets/AI"
  private_service_connection {
    name                           = data.terraform_remote_state.global.outputs.ai.services.name
    private_connection_resource_id = data.terraform_remote_state.global.outputs.ai.services.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_services_cognitive[0].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_services_cognitive[0].id
    ]
  }
  depends_on = [
    azurerm_private_endpoint.ai_services_open
  ]
}
