terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.20.0"
    }
  }
}


# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = " P"

}


resource "azurerm_ssh_public_key" "example" {
  name                = "test-ssh-mr"
  resource_group_name = "Smtx_essentials"
  location            = "uk south"
  public_key          = file("~/.ssh/id_rsa.pub")
}

# Create a resource group
resource "azurerm_resource_group" "mr-playground-south" {
  name     = "multi-region-plgd-south"
  location = "uk south"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "mr-vnet-south" {
  name                = "uk-south-vnet-mr"
  resource_group_name = azurerm_resource_group.mr-playground-south.name
  location            = azurerm_resource_group.mr-playground-south.location
  address_space       = ["10.0.0.0/16"]
}


resource "azurerm_subnet" "mr-south-subnet" {
  name = "main-west-subnet"
  resource_group_name = azurerm_resource_group.mr-playground-south.name
  virtual_network_name = azurerm_virtual_network.mr-vnet-south.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network_peering" "mr-vnet-peering-sout" {
  name = "peerSouth2West"
  resource_group_name = azurerm_resource_group.mr-playground-south.name
  virtual_network_name = azurerm_virtual_network.mr-vnet-south.name
  remote_virtual_network_id = azurerm_virtual_network.mr-vnet-west.id  
}










resource "azurerm_resource_group" "mr-playground-west" {
    name   = "multi-region-plgd-west"
    location =  "uk west"
  
}

resource "azurerm_virtual_network" "mr-vnet-west" {
  name                = "uk-west-vnet-mr"
  resource_group_name = azurerm_resource_group.mr-playground-west.name
  location            = azurerm_resource_group.mr-playground-west.location
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "mr-west-subnet" {
  name = "main-west-subnet"
  resource_group_name = azurerm_resource_group.mr-playground-west.name
  virtual_network_name = azurerm_virtual_network.mr-vnet-west.name
  address_prefixes = ["10.10.1.0/24"]
  
}

resource "azurerm_virtual_network_peering" "mr-vnet-peering-west" {
  name = "peerWest2South"
  resource_group_name = azurerm_resource_group.mr-playground-west.name
  virtual_network_name = azurerm_virtual_network.mr-vnet-west.name
  remote_virtual_network_id = azurerm_virtual_network.mr-vnet-south.id  
}



