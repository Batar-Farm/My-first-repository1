module "resource_group" {
  source = "../../Modules/azurerm_resource_group"
  rg_name  = "mango-rg22"
  location = "centralindia"
}

module "vnet" {
    depends_on = [ module.resource_group ]
    source = "../../Modules/azurerm_vnet"
    vnet_name = "mango-vnet"
    rg_name  = "mango-rg22"
    location = "centralindia"

}

module "frontend_subnet" {
    depends_on = [ module.vnet ]
    source = "../../Modules/azurerm_subnet"
    subnet_name = "mango-frontend_subnet"
    vnet_name = "mango-vnet"
    rg_name  = "mango-rg22"
    address_prefixes = ["10.0.1.0/24"]
}
module "backend_subnet" {
    depends_on = [ module.vnet ]
    source = "../../Modules/azurerm_subnet"
    subnet_name = "mango-backend_subnet"
    vnet_name = "mango-vnet"
    rg_name  = "mango-rg22"
    address_prefixes = ["10.0.2.0/24"]
}

module "nsg_frontend" {
    depends_on = [ module.frontend_subnet ]
    source = "../../Modules/azurerm_nsg"
    nsg_name = "mango-frontend-nsg"
    rg_name  = "mango-rg22"
    location = "centralindia"
    security_rule_name = "Allow-HTTP"
}

module "nsg_backend" {
    depends_on = [ module.backend_subnet ]
    source = "../../Modules/azurerm_nsg"
    nsg_name = "mango-backend-nsg"
    rg_name  = "mango-rg22"
    location = "centralindia"
    security_rule_name = "Allow-HTTP"
}

module "frontend_public_ip" {
    depends_on = [ module.resource_group ]
    source = "../../Modules/azurerm_public_ip"
    pip_name = "mango-frontend-public-ip"
    rg_name  = "mango-rg22"
    location = "centralindia"
}
module "backend_public_ip" {
    depends_on = [ module.resource_group ]
    source = "../../Modules/azurerm_public_ip"
    pip_name = "mango-backend_public-ip"
    rg_name  = "mango-rg22"
    location = "centralindia"
}

module "keyvault" {
    depends_on = [ module.resource_group ]
    source = "../../Modules/azurerm_keyvault"
    keyvault_name = "mango-keyvault"
    rg_name  = "mango-rg22"
    location = "centralindia"
    soft_delete_retention_days = 7
    sku_name = "standard"  
}

module "keyvault_secret_vm_id" {
    depends_on = [ module.keyvault ]
    source = "../../Modules/azurerm_keyvault_secret"
    keyvault_name = "mango-keyvault"
    secret_value = var.vm_id_secret
    secret_name = "own-username-secret"
    rg_name = "mango-rg22"
}

module "keyvault_secret_vm_password" {
    depends_on = [ module.keyvault ]
    source = "../../Modules/azurerm_keyvault_secret"
    keyvault_name = "mango-keyvault"
    secret_value = var.vm_password_secret
    secret_name = "own-password-secret"
    rg_name = "mango-rg22"
}

module "keyvault_secret_administrator_id" {
    depends_on = [ module.keyvault ]
    source = "../../Modules/azurerm_keyvault_secret"
    keyvault_name = "mango-keyvault"
    secret_value = var.server_admin_id_secret
    secret_name = "server-admin-id-secret"
    rg_name = "mango-rg22"
}

module "keyvault_secret_administrator_password" {
    depends_on = [ module.keyvault ]
    source = "../../Modules/azurerm_keyvault_secret"
    keyvault_name = "mango-keyvault"
    secret_value =  var.server_admin_password_secret
    secret_name = "server-admin-password-secret"
    rg_name = "mango-rg22"
}



module "frontend_vm" {
    depends_on = [ module.frontend_public_ip, module.frontend_subnet, module.nsg_frontend, module.keyvault_secret_vm_id, module.keyvault_secret_vm_password ]
    source = "../../Modules/azurerm_linux_vm"
    vm_name = "mango-frontend-vm"
    rg_name  = "mango-rg22"
    location = "centralindia"
    vm_size = "Standard_D2s_v3"
    os_disk_storage_account_type = "Standard_LRS"
    os_image_publisher = "Canonical"
    os_image_offer = "0001-com-ubuntu-server-jammy"
    os_image_sku = "22_04-lts"
    nic_name = "mango-frontend-nic"
    ip_config_name = "mango-frontend-ip-config"
    vnet_name = "mango-vnet"
    subnet_name = "mango-frontend_subnet"
    pip_name = "mango-frontend-public-ip"
    keyvault_name = "mango-keyvault"
    admin_username = "own-username-secret"
    admin_password_name =  "own-password-secret"

}

module "backend_vm" {
    depends_on = [ module.backend_public_ip, module.backend_subnet, module.nsg_backend, module.keyvault_secret_vm_id, module.keyvault_secret_vm_password ]
    source = "../../Modules/azurerm_linux_vm"
    vm_name = "mango-backend-vm"
    rg_name  = "mango-rg22"
    location = "centralindia"
    vm_size = "Standard_D2s_v3"
    os_disk_storage_account_type = "Standard_LRS"
    os_image_publisher = "Canonical"
    os_image_offer = "0001-com-ubuntu-server-jammy"
    os_image_sku = "22_04-lts"
    nic_name = "mango-backend-nic"
    ip_config_name = "mango-backend-ip-config"
    vnet_name = "mango-vnet"
    subnet_name = "mango-backend_subnet"
    pip_name = "mango-backend-public-ip"
    keyvault_name = "mango-keyvault"
    admin_username = "own-username-secret"
    admin_password_name = "own-password-secret"

}

module "sql_server" {
    depends_on = [ module.keyvault_secret_administrator_id, module.keyvault_secret_administrator_password ]
    source = "../../Modules/azurerm_sql_server"
    sql_server_name = "mango-sql-server"
    rg_name  = "mango-rg22"
    location = "centralindia"
    administrator_login_id= "server-admin-id-secret"
    administrator_login_password_name = "server-admin-password-secret"
    keyvault_name = "mango-keyvault"
    
}


module "sql_database" {
    depends_on = [ module.sql_server ]
    source = "../../Modules/azurerm_database"
    database_name = "mango-sql-database"
    database_collation = "SQL_Latin1_General_CP1_CI_AS"
    enclave_type = "Default"
    database_max_size = 10
    database_sku_name = "S0"
    sql_server_name = "mango-sql-server"
    rg_name = "mango-rg22"
}
    