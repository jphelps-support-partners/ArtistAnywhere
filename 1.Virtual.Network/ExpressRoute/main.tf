terraform {
  required_version = ">= 1.6.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.82.0"
    }
  }
}

provider azurerm {
  features {
  }
}

variable regionName {
  type = string
}

variable resourceGroupName {
  type = string
}

resource azurerm_resource_group express_route {
  name     = var.resourceGroupName
  location = var.regionName
}
