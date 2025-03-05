output "public_ip_south" {
    value = azurerm_public_ip.ss-south-lb.ip_address
  
}

output "public_ip_west" {
    value = azurerm_public_ip.ss-west-lb.ip_address
  
}