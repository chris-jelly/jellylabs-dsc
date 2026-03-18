terraform {
  required_version = "~> 1.11.0"

  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.64"
    }
  }
}

provider "azurerm" {
  features {}
}
