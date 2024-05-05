##########################################################################
# OpenAI (https://learn.microsoft.com/azure/ai-services/openai/overview) #
##########################################################################

resource azurerm_cognitive_account ai_open {
  count                 = var.ai.open.enable ? 1 : 0
  name                  = var.ai.open.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.open.tier
  custom_subdomain_name = var.ai.open.domainName != "" ? var.ai.open.domainName : var.ai.open.name
  kind                  = "OpenAI"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_acls {
    default_action = "Deny"
    virtual_network_rules {
      subnet_id = data.azurerm_subnet.ai.id
    }
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
  dynamic customer_managed_key {
    for_each = module.global.keyVault.enable && var.ai.encryption.enable ? [1] : []
    content {
      key_vault_key_id = data.azurerm_key_vault_key.data_encryption[0].id
    }
  }
}

resource azurerm_private_dns_zone ai_open {
  count               = var.ai.open.enable ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.ai.name
}

resource azurerm_private_dns_zone_virtual_network_link ai_open {
  for_each = {
    for virtualNetwork in local.virtualNetworks : virtualNetwork.key => virtualNetwork if var.ai.open.enable
  }
  name                  = "${lower(each.value.key)}-ai-open"
  resource_group_name   = azurerm_private_dns_zone.ai_open[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ai_open[0].name
  virtual_network_id    = each.value.id
}

resource azurerm_private_endpoint ai_open {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet if var.ai.open.enable && subnet.virtualNetworkEdgeZone == ""
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-open"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_open[0].name
    private_connection_resource_id = azurerm_cognitive_account.ai_open[0].id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai_open[each.value.virtualNetworkKey].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai_open[0].id
    ]
  }
}
