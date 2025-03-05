#!/bin/bash
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y apache2
sudo systemctl enable apache2
sudo systemctl start apache2
sudo ufw allow 'Apache'