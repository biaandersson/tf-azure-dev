resource "azurerm_resource_group" "mtc_rg" {
  location = "Sweden Central"
  name     = "mtc-resources"

  tags = {
    environment = "development"
  }
}

resource "azurerm_virtual_network" "mtc_dev_vnet" {
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  name                = "mtc-dev-network"
  address_space       = ["10.123.0.0/16"]
}

resource "azurerm_subnet" "mtc_dev_subnet" {
  virtual_network_name = azurerm_virtual_network.mtc_dev_vnet.name
  resource_group_name  = azurerm_resource_group.mtc_rg.name
  address_prefixes     = ["10.123.1.0/24"]
  name                 = "mtc-dev-subnet"
}

resource "azurerm_network_security_group" "mtc_dev_sg" {
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  name                = "mtc-dev-sg"

  tags = {
    environment = "development"
  }
}

resource "azurerm_network_security_rule" "mtc_dev_rule" {
  name                        = "mtc-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "213.113.67.149/32"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mtc_rg.name
  network_security_group_name = azurerm_network_security_group.mtc_dev_sg.name
}

resource "azurerm_subnet_network_security_group_association" "mtc_dev_subnet_sg" {
  network_security_group_id = azurerm_network_security_group.mtc_dev_sg.id
  subnet_id                 = azurerm_subnet.mtc_dev_subnet.id
}

resource "azurerm_public_ip" "mtc_dev_public_ip" {
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  name                = "mtc-dev-public-ip"
  allocation_method   = "Dynamic"

  tags = {
    environment = "development"
  }
}

resource "azurerm_network_interface" "mtc_dev_nic" {
  location            = azurerm_resource_group.mtc_rg.location
  resource_group_name = azurerm_resource_group.mtc_rg.name
  name                = "mtc-dev-nic"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.mtc_dev_public_ip.id
    subnet_id                     = azurerm_subnet.mtc_dev_subnet.id
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "development"
  }
}

resource "azurerm_linux_virtual_machine" "mtc_dev_vm" {
  network_interface_ids = [azurerm_network_interface.mtc_dev_nic.id]
  location              = azurerm_resource_group.mtc_rg.location
  resource_group_name   = azurerm_resource_group.mtc_rg.name
  name                  = "mtc-dev-vm01"
  size                  = "Standard_B1s"
  admin_username        = "opsadmin"

  custom_data = filebase64("customdata.tpl")

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "opsadmin"
    public_key = file("~/.ssh/azureops.pub")
  }

  tags = {
    environment = "development"
  }
}