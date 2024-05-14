########################################################################
# Bastion (https://learn.microsoft.com/azure/bastion/bastion-overview) #
########################################################################

variable bastion {
  type = object({
    enable              = bool
    sku                 = string
    scaleUnitCount      = number
    enableFileCopy      = bool
    enableCopyPaste     = bool
    enableIpConnect     = bool
    enableTunneling     = bool
    enablePerRegion     = bool
    enableShareableLink = bool
  })
}

locals {
  bastionNetworks = var.bastion.enable ? var.bastion.enablePerRegion ? local.virtualNetworks : [local.virtualNetwork] : []
}

resource azurerm_network_security_group bastion {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet if subnet.name == "AzureBastionSubnet"
  }
  name                = "${each.value.virtualNetworkName}-${each.value.name}"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  security_rule {
    name                       = "AllowInHTTPS"
    priority                   = 2000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }
  security_rule {
    name                       = "AllowInGatewayManager"
    priority                   = 2100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "GatewayManager"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }
  security_rule {
    name                       = "AllowInBastion"
    priority                   = 2200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges = [
      "8080",
      "5701"
    ]
  }
  security_rule {
    name                       = "AllowInLoadBalancer"
    priority                   = 2300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }
  security_rule {
    name                       = "AllowOutSSH-RDP"
    priority                   = 2000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges = [
      "22",
      "3389"
    ]
  }
  security_rule {
    name                       = "AllowOutAzureCloud"
    priority                   = 2100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "AzureCloud"
    destination_port_range     = "443"
  }
  security_rule {
    name                       = "AllowOutBastion"
    priority                   = 2200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges = [
      "8080",
      "5701"
    ]
  }
  security_rule {
    name                       = "AllowOutBastionSession"
    priority                   = 2300
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "80"
  }
  depends_on = [
    azurerm_virtual_network.studio
  ]
}

resource azurerm_subnet_network_security_group_association bastion {
  for_each = {
    for subnet in local.virtualNetworksSubnetsSecurity : subnet.key => subnet if subnet.name == "AzureBastionSubnet" && subnet.virtualNetworkEdgeZone == ""
  }
  subnet_id                 = "${each.value.virtualNetworkId}/subnets/AzureBastionSubnet"
  network_security_group_id = azurerm_network_security_group.bastion[each.value.key].id
  depends_on = [
    azurerm_subnet.studio
  ]
}

resource azurerm_public_ip bastion {
  for_each = {
    for virtualNetwork in local.bastionNetworks : virtualNetwork.key => virtualNetwork
  }
  name                = "Bastion-${each.value.name}"
  resource_group_name = each.value.resourceGroupName
  location            = each.value.regionName
  sku                 = "Standard"
  allocation_method   = "Static"
  depends_on = [
    azurerm_subnet_network_security_group_association.bastion
  ]
}

resource azurerm_bastion_host studio {
  for_each = {
    for virtualNetwork in local.bastionNetworks : virtualNetwork.key => virtualNetwork
  }
  name                   = "Bastion-${each.value.name}"
  resource_group_name    = each.value.resourceGroupName
  location               = each.value.regionName
  sku                    = var.bastion.sku
  scale_units            = var.bastion.scaleUnitCount
  file_copy_enabled      = var.bastion.enableFileCopy
  copy_paste_enabled     = var.bastion.enableCopyPaste
  ip_connect_enabled     = var.bastion.enableIpConnect
  tunneling_enabled      = var.bastion.enableTunneling
  shareable_link_enabled = var.bastion.enableShareableLink
  ip_configuration {
    name                 = "ipConfig"
    public_ip_address_id = azurerm_public_ip.bastion[each.value.key].id
    subnet_id            = "${each.value.id}/subnets/AzureBastionSubnet"
  }
  depends_on = [
    azurerm_subnet.studio
  ]
}
