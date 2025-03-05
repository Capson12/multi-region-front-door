resource "azurerm_linux_virtual_machine_scale_set" "mr_scale_set_south" {
    name = "LinuxScaleSetSouth"
    location = azurerm_resource_group.mr-playground-south.location
    resource_group_name = azurerm_resource_group.mr-playground-south.name
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
    name = "south_nic"
    primary = true

    ip_configuration {

        name = "internal"
        primary = true
        subnet_id = azurerm_subnet.mr-south-subnet.id
        load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.ss-bp-pool-south.id]
      
    }
    
  }

  custom_data = filebase64("install_apache.sh")


}


resource "azurerm_public_ip" "ss-south-lb-ip" {
  name                = "SouthPublicIPForLB"
  location            = azurerm_resource_group.mr-playground-south.location
  resource_group_name = azurerm_resource_group.mr-playground-south.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_lb" "ss-south-lb" {
  name                = "SouthBalancer"
  location            = azurerm_public_ip.ss-south-lb-ip.location
  resource_group_name = azurerm_public_ip.ss-south-lb-ip.resource_group_name
  sku = "Standard"


  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.ss-south-lb-ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "ss-bp-pool-south" {
  name = "bp"
  loadbalancer_id = azurerm_lb.ss-south-lb.id 
}

resource "azurerm_lb_probe" "ss-lb-probe-south" {
  loadbalancer_id = azurerm_lb.ss-south-lb.id
  name = "80-health-probe-south"
  protocol = "Tcp"
  port = 80
  
}

resource "azurerm_lb_rule" "ss-lb-rule-south" {
  loadbalancer_id = azurerm_lb.ss-south-lb.id
  name = "lb-80-rule"
  protocol = "Tcp"
  frontend_port = 80
  backend_port = 80
  frontend_ip_configuration_name = azurerm_lb.ss-south-lb.frontend_ip_configuration[0].name
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.ss-bp-pool-south.id]
  probe_id = azurerm_lb_probe.ss-lb-probe-south.id
  
}


resource "azurerm_network_security_group" "south_nsg" {
  name                = "VMSS-nsg"
  location            = azurerm_resource_group.mr-playground-south.location
  resource_group_name = azurerm_resource_group.mr-playground-south.name
  

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

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_ass" {
  subnet_id                 = azurerm_subnet.mr-south-subnet.id
  network_security_group_id = azurerm_network_security_group.south_nsg.id
}



resource "azurerm_public_ip" "mr_nat_ip" {
  name                = "nat-ip"
  location            = azurerm_resource_group.mr-playground-south.location
  resource_group_name = azurerm_resource_group.mr-playground-south.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "mr_nat_gate" {
  name                = "south-NatGateway"
  location            = azurerm_resource_group.mr-playground-south.location
  resource_group_name = azurerm_resource_group.mr-playground-south.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "mr_nat_ass" {
  nat_gateway_id       = azurerm_nat_gateway.mr_nat_gate.id
  public_ip_address_id = azurerm_public_ip.mr_nat_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "south_sub_nat" {
  subnet_id      = azurerm_subnet.mr-south-subnet.id
  nat_gateway_id = azurerm_nat_gateway.mr_nat_gate.id
}