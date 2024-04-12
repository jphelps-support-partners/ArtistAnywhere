#####################################################################################
# AI Speech (https://learn.microsoft.com/azure/ai-services/speech-service/overview) #
#####################################################################################

resource azurerm_cognitive_account ai_speech {
  name                  = var.ai.speech.name
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  sku_name              = var.ai.speech.tier
  custom_subdomain_name = var.ai.speech.domainName != "" ? var.ai.speech.domainName : var.ai.speech.name
  kind                  = "SpeechServices"
  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.studio.id
    ]
  }
  network_acls {
    default_action = "Deny"
    ip_rules = [
      jsondecode(data.http.client_address.response_body).ip
    ]
  }
  storage {
    identity_client_id = data.azurerm_user_assigned_identity.studio.client_id
    storage_account_id = data.azurerm_storage_account.studio.id
  }
}

resource azurerm_private_endpoint ai_speech {
  for_each = {
    for subnet in local.virtualNetworksSubnetCompute : subnet.key => subnet
  }
  name                = "${lower(each.value.virtualNetworkName)}-ai-speech"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  subnet_id           = "${each.value.virtualNetworkId}/subnets/${each.value.name}"
  private_service_connection {
    name                           = azurerm_cognitive_account.ai_speech.name
    private_connection_resource_id = azurerm_cognitive_account.ai_speech.id
    is_manual_connection           = false
    subresource_names = [
      "account"
    ]
  }
  private_dns_zone_group {
    name = azurerm_private_dns_zone_virtual_network_link.ai[each.value.virtualNetworkName].name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.ai.id
    ]
  }
}
