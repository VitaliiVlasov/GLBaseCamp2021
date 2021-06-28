resource "azurerm_resource_group" "web" {
  name     = "web-lb"
  location = "West Europe"
}

resource "azurerm_network_security_group" "allow_http" {
  name                = "allow-http"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "allow http"
  }
}

resource "azurerm_virtual_network" "web" {
  name = "network-for-web-application"
  address_space = [
  "10.0.0.0/16"]
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
}

resource "azurerm_subnet" "subnets" {
  count                = 2
  name                 = "subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.web.name
  virtual_network_name = azurerm_virtual_network.web.name
  address_prefixes = [
  "10.0.${count.index + 1}.0/24"]
}

resource "azurerm_public_ip" "public_ips" {
  count               = 2
  name                = "pubic-ip-${count.index + 1}"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "interfaces" {
  count               = 2
  name                = "interface-${count.index + 1}"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets[count.index].id
    public_ip_address_id          = azurerm_public_ip.public_ips[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_subnet_network_security_group_association" "sg_associations" {
  count                     = 2
  subnet_id                 = azurerm_subnet.subnets[count.index].id
  network_security_group_id = azurerm_network_security_group.allow_http.id
}

resource "azurerm_linux_virtual_machine" "example" {
  count               = 2
  name                = "web-${count.index + 1}"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  zone                = count.index + 1
  size                = "Standard_F2"
  admin_username      = "adminuser"
  custom_data         = filebase64("script.sh")

  network_interface_ids = [element(azurerm_network_interface.interfaces.*.id, count.index)]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "lb" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "web_lb" {
  name                = "LoadBalancer-for-web-app"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_backend_address_pool_address" "address_pool" {
  count                   = 2
  name                    = "address-pool-${count.index + 1}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  virtual_network_id      = azurerm_virtual_network.web.id
  ip_address              = "10.0.${count.index + 1}.4"
}

resource "azurerm_lb_probe" "http_probe" {
  resource_group_name = azurerm_resource_group.web.name
  loadbalancer_id     = azurerm_lb.web_lb.id
  name                = "http-running-probe"
  port                = 80
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = azurerm_resource_group.web.name
  loadbalancer_id                = azurerm_lb.web_lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  probe_id                       = azurerm_lb_probe.http_probe.id
  frontend_ip_configuration_name = "PublicIPAddress"
}