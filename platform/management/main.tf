# Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.region
}

module "log_workspace" {
  source              = "../../modules/monitoring"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  region              = var.region
  project             = var.project
  environment         = var.environment
  alert_email         = var.alert_email
  default_tags        = local.default_tags
}



module "keyvault" {
  source              = "../../modules/security"
  project             = var.project
  environment         = var.environment
  region              = var.region
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  default_tags        = local.default_tags
}

#-------------------------------------------------------
resource "azurerm_monitor_data_collection_rule" "change_tracking" {
  description                 = "Data collection rule for Change Tracking and Inventory."
  location                    = var.region
  name                        = "dcr-change-tracking-global"
  resource_group_name         = azurerm_resource_group.main.name

  data_flow {
    destinations  = ["change-tracking-servicenow"]
    streams       = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
  }
  data_sources {
    extension {
      extension_json = jsonencode({
        enableFiles     = true
        enableInventory = true
        enableRegistry  = true
        enableServices  = true
        enableSoftware  = true
        fileSettings = {
          fileCollectionFrequency = 2700
        }
        inventorySettings = {
          inventoryCollectionFrequency = 36000
        }
        registrySettings = {
          registryCollectionFrequency = 3000
          registryInfo = [{
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Group Policy\\Scripts\\Startup"
            name        = "Registry_1"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Group Policy\\Scripts\\Shutdown"
            name        = "Registry_2"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Run"
            name        = "Registry_3"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Active Setup\\Installed Components"
            name        = "Registry_4"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\ShellEx\\ContextMenuHandlers"
            name        = "Registry_5"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\Background\\ShellEx\\ContextMenuHandlers"
            name        = "Registry_6"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\Shellex\\CopyHookHandlers"
            name        = "Registry_7"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers"
            name        = "Registry_8"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers"
            name        = "Registry_9"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects"
            name        = "Registry_10"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects"
            name        = "Registry_11"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Internet Explorer\\Extensions"
            name        = "Registry_12"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Internet Explorer\\Extensions"
            name        = "Registry_13"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32"
            name        = "Registry_14"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32"
            name        = "Registry_15"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\KnownDlls"
            name        = "Registry_16"
            recurse     = true
            valueName   = ""
            }, {
            description = ""
            enabled     = false
            groupTag    = "Recommended"
            keyName     = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\Notify"
            name        = "Registry_17"
            recurse     = true
            valueName   = ""
          }]
        }
        servicesSettings = {
          serviceCollectionFrequency = 1800
        }
        softwareSettings = {
          softwareCollectionFrequency = 1800
        }
      })
      extension_name     = "ChangeTracking-Windows"
      input_data_sources = []
      name               = "CTDataSource-Windows"
      streams            = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
    }
    extension {
      extension_json = jsonencode({
        enableFiles     = true
        enableInventory = true
        enableRegistry  = false
        enableServices  = true
        enableSoftware  = true
        fileSettings = {
          fileCollectionFrequency = 900
          fileInfo = [{
            destinationPath       = "/etc/.*.conf"
            enabled               = true
            groupTag              = "Recommended"
            links                 = "Follow"
            maxContentsReturnable = 5000000
            maxOutputSize         = 500000
            name                  = "ChangeTrackingLinuxPath_default"
            pathType              = "File"
            recurse               = true
            type                  = "File"
            useSudo               = true
          }]
        }
        inventorySettings = {
          inventoryCollectionFrequency = 36000
        }
        servicesSettings = {
          serviceCollectionFrequency = 300
        }
        softwareSettings = {
          softwareCollectionFrequency = 300
        }
      })
      extension_name     = "ChangeTracking-Linux"
      input_data_sources = []
      name               = "CTDataSource-Linux"
      streams            = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
    }
  }


  destinations {
    log_analytics {
      name                  = "change-tracking-servicenow"
      workspace_resource_id = module.log_workspace.log_analytics_id
    }
  }
}


#------------------------

# resource "azurerm_monitor_data_collection_rule" "res-0" {
#   data_collection_endpoint_id = ""
#   description                 = "Data collection rule for ServiceNow."
#   kind                        = ""
#   location                    = var.region
#   name                        = "dcr-servicenow-global"
#   resource_group_name         = azurerm_resource_group.main.name
#   tags                        = {}
#   data_flow {
#     built_in_transform = ""
#     destinations       = ["Microsoft-CT-Dest"]
#     output_stream      = ""
#     streams            = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
#     transform_kql      = ""
#   }
# data_sources {
#   extension {
#     extension_json = jsonencode({
#       enableFiles     = true
#       enableInventory = true
#       enableRegistry  = true
#       enableServices  = true
#       enableSoftware  = true
#       fileSettings = {
#         fileCollectionFrequency = 2700
#       }
#       inventorySettings = {
#         inventoryCollectionFrequency = 36000
#       }
#       registrySettings = {
#         registryCollectionFrequency = 3000
#         registryInfo = [{
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Group Policy\\Scripts\\Startup"
#           name        = "Registry_1"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Group Policy\\Scripts\\Shutdown"
#           name        = "Registry_2"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Run"
#           name        = "Registry_3"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Active Setup\\Installed Components"
#           name        = "Registry_4"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\ShellEx\\ContextMenuHandlers"
#           name        = "Registry_5"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\Background\\ShellEx\\ContextMenuHandlers"
#           name        = "Registry_6"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\Shellex\\CopyHookHandlers"
#           name        = "Registry_7"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers"
#           name        = "Registry_8"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers"
#           name        = "Registry_9"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects"
#           name        = "Registry_10"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects"
#           name        = "Registry_11"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Internet Explorer\\Extensions"
#           name        = "Registry_12"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Internet Explorer\\Extensions"
#           name        = "Registry_13"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32"
#           name        = "Registry_14"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32"
#           name        = "Registry_15"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\KnownDlls"
#           name        = "Registry_16"
#           recurse     = true
#           valueName   = ""
#           }, {
#           description = ""
#           enabled     = false
#           groupTag    = "Recommended"
#           keyName     = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\Notify"
#           name        = "Registry_17"
#           recurse     = true
#           valueName   = ""
#         }]
#       }
#       servicesSettings = {
#         serviceCollectionFrequency = 1800
#       }
#       softwareSettings = {
#         softwareCollectionFrequency = 1800
#       }
#     })
#     extension_name     = "ChangeTracking-Windows"
#     input_data_sources = []
#     name               = "CTDataSource-Windows"
#     streams            = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
#   }
#   extension {
#     extension_json = jsonencode({
#       enableFiles     = true
#       enableInventory = true
#       enableRegistry  = false
#       enableServices  = true
#       enableSoftware  = true
#       fileSettings = {
#         fileCollectionFrequency = 900
#         fileInfo = [{
#           destinationPath       = "/etc/.*.conf"
#           enabled               = true
#           groupTag              = "Recommended"
#           links                 = "Follow"
#           maxContentsReturnable = 5000000
#           maxOutputSize         = 500000
#           name                  = "ChangeTrackingLinuxPath_default"
#           pathType              = "File"
#           recurse               = true
#           type                  = "File"
#           useSudo               = true
#         }]
#       }
#       inventorySettings = {
#         inventoryCollectionFrequency = 36000
#       }
#       servicesSettings = {
#         serviceCollectionFrequency = 300
#       }
#       softwareSettings = {
#         softwareCollectionFrequency = 300
#       }
#     })
#     extension_name     = "ChangeTracking-Linux"
#     input_data_sources = []
#     name               = "CTDataSource-Linux"
#     streams            = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
#   }
# }
#   destinations {
#     log_analytics {
#       name                  = "Microsoft-CT-Dest"
#       workspace_resource_id = module.log_workspace.log_analytics_id
#     }
#   }
# }
