######################################################################
# Monitor (https://learn.microsoft.com/azure/azure-monitor/overview) #
######################################################################

data azurerm_log_analytics_workspace studio {
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
}

data azurerm_application_insights studio {
  name                = module.global.monitor.name
  resource_group_name = module.global.resourceGroupName
}

resource azurerm_private_dns_zone monitor {
  name                = "privatelink.monitor.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone monitor_opinsights_oms {
  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone monitor_opinsights_ods {
  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone monitor_automation {
  name                = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_private_dns_zone_virtual_network_link monitor {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "monitor-${lower(each.value.regionName)}"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.monitor.name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link monitor_opinsights_oms {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "monitor-opinsights-oms-${lower(each.value.regionName)}"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_opinsights_oms.name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link monitor_opinsights_ods {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "monitor-opinsights-ods-${lower(each.value.regionName)}"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_opinsights_ods.name
  virtual_network_id    = each.value.id
}

resource azurerm_private_dns_zone_virtual_network_link monitor_automation {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.name => virtualNetwork
  }
  name                  = "monitor-automation-${lower(each.value.regionName)}"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.monitor_automation.name
  virtual_network_id    = each.value.id
}

resource azurerm_private_endpoint monitor {
  for_each = {
    for subnet in local.virtualNetworksSubnetStorage : "${subnet.virtualNetworkName}-${subnet.name}" => subnet
  }
  name                = "${azurerm_monitor_private_link_scope.monitor.name}-monitor"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_monitor_private_link_scope.monitor.name
    private_connection_resource_id = azurerm_monitor_private_link_scope.monitor.id
    is_manual_connection           = false
    subresource_names = [
      "azuremonitor"
    ]
  }
  private_dns_zone_group {
    name = azurerm_monitor_private_link_scope.monitor.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.monitor.id,
      azurerm_private_dns_zone.monitor_opinsights_oms.id,
      azurerm_private_dns_zone.monitor_opinsights_ods.id,
      azurerm_private_dns_zone.monitor_automation.id,
      azurerm_private_dns_zone.storage_blob.id
    ]
  }
  depends_on = [
    azurerm_subnet.studio,
    azurerm_private_dns_zone_virtual_network_link.monitor,
    azurerm_private_dns_zone_virtual_network_link.monitor_opinsights_oms,
    azurerm_private_dns_zone_virtual_network_link.monitor_opinsights_ods,
    azurerm_private_dns_zone_virtual_network_link.monitor_automation,
    azurerm_private_endpoint.storage_file
  ]
}

resource azurerm_monitor_private_link_scope monitor {
  name                = module.global.monitor.name
  resource_group_name = azurerm_resource_group.network.name
}

resource azurerm_monitor_private_link_scoped_service monitor_workspace {
  name                = "${module.global.monitor.name}-workspace"
  resource_group_name = azurerm_resource_group.network.name
  linked_resource_id  = data.azurerm_log_analytics_workspace.studio.id
  scope_name          = azurerm_monitor_private_link_scope.monitor.name
}

resource azurerm_monitor_private_link_scoped_service monitor_insight {
  name                = "${module.global.monitor.name}-insight"
  resource_group_name = azurerm_resource_group.network.name
  linked_resource_id  = data.azurerm_application_insights.studio.id
  scope_name          = azurerm_monitor_private_link_scope.monitor.name
}
