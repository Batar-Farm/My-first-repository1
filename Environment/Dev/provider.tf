terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.33.0"
    }
  }
}

provider "azurerm" {
features {}
subscription_id = "4a8882d8-040a-43b9-81c8-844e324752c0"
}