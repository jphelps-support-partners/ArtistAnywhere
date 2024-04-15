regionName = "" # Set Azure region name from "az account list-locations --query [].name"

resourceGroupName = "ArtistAnywhere.Network" # Alphanumeric, underscores, hyphens, periods and parenthesis are allowed

#######################################################################################################
# ExpressRoute         (https://learn.microsoft.com/azure/expressroute/expressroute-introduction      #
# ExpressRoute Circuit (https://learn.microsoft.com/azure/expressroute/expressroute-circuit-peerings) #
#######################################################################################################

expressRouteCircuit = {
  enable          = false
  name            = ""
  serviceTier     = "Standard" # https://learn.microsoft.com/azure/expressroute/plan-manage-cost#local-vs-standard-vs-premium
  serviceProvider = ""
  peeringLocation = ""
  bandwidthMbps   = 50
  unlimitedData   = false
}

#####################################################################################################################
# ExpressRoute Gateway (https://learn.microsoft.com/azure/expressroute/expressroute-about-virtual-network-gateways) #
#####################################################################################################################

expressRouteGateway = {
  enable     = false
  name       = ""
  serviceSku = "Standard" # https://learn.microsoft.com/azure/expressroute/expressroute-about-virtual-network-gateways#gwsku
  circuitConnection = {
    circuitId        = ""
    authorizationKey = ""
    enableFastPath   = false # https://learn.microsoft.com/azure/expressroute/about-fastpath
  }
}

#################################################################################################
# Virtual Network (https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview) #
#################################################################################################

virtualNetwork = {
  name              = ""
  resourceGroupName = ""
}
