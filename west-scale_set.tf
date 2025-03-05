resource "azurerm_linux_virtual_machine_scale_set" "mr_scale_set_west" {
    name = "LinuxScaleSetWest"
    location = azurerm_resource_group.mr-playground-west.location
    resource_group_name = azurerm_resource_group.mr-playground-west.name
    admin_username = "azureuser" 
    sku = "Standard_B2s"
    instances = 2

    source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching =  "ReadWrite"
    
  }

  admin_ssh_key {
    username = "azureuser"
    public_key = file("vm.pub")
  }

  network_interface {
    name = "west_nic"
    primary = true

    ip_configuration {

        name = "internal"
        primary = true
        subnet_id = azurerm_subnet.mr-west-subnet.id
        load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.ss-bp-pool.id]
      
    }
    
  }

  custom_data = filebase64("install_apache.sh")


}


resource "azurerm_public_ip" "ss-west-lb-ip" {
  name                = "WestPublicIPForLB"
  location            = azurerm_resource_group.mr-playground-west.location
  resource_group_name = azurerm_resource_group.mr-playground-west.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_lb" "ss-west-lb" {
  name                = "WestBalancer"
  location            = azurerm_public_ip.ss-west-lb-ip.location
  resource_group_name = azurerm_public_ip.ss-west-lb-ip.resource_group_name
  sku = "Standard"


  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.ss-west-lb-ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "ss-bp-pool" {
  name = "bp"
  loadbalancer_id = azurerm_lb.ss-west-lb.id
  
  
}

resource "azurerm_lb_probe" "ss-lb-probe" {
  loadbalancer_id = azurerm_lb.ss-west-lb.id
  name = "80-health-probe"
  protocol = "Tcp"
  port = 80
  
}

resource "azurerm_lb_rule" "ss-lb-rule" {
  loadbalancer_id = azurerm_lb.ss-west-lb.id
  name = "lb-80-rule"
  protocol = "Tcp"
  frontend_port = 80
  backend_port = 80
  frontend_ip_configuration_name = azurerm_lb.ss-west-lb.frontend_ip_configuration[0].name
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.ss-bp-pool.id]
  probe_id = azurerm_lb_probe.ss-lb-probe.id
  disable_outbound_snat = true
  
}



resource "azurerm_network_security_group" "example" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.mr-playground-west.location
  resource_group_name = azurerm_resource_group.mr-playground-west.name
  

  security_rule {
    name                       = "80intbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }


  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.mr-west-subnet.id
  network_security_group_id = azurerm_network_security_group.example.id
}



resource "azurerm_public_ip" "example" {
  name                = "example-PIP"
  location            = azurerm_resource_group.mr-playground-west.location
  resource_group_name = azurerm_resource_group.mr-playground-west.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "example" {
  name                = "example-NatGateway"
  location            = azurerm_resource_group.mr-playground-west.location
  resource_group_name = azurerm_resource_group.mr-playground-west.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "example" {
  nat_gateway_id       = azurerm_nat_gateway.example.id
  public_ip_address_id = azurerm_public_ip.example.id
}

resource "azurerm_subnet_nat_gateway_association" "example" {
  subnet_id      = azurerm_subnet.mr-west-subnet.id
  nat_gateway_id = azurerm_nat_gateway.example.id
}