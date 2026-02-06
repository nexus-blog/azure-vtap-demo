// ============================================================================
// Azure vTAP Demo — Infrastructure Bicep Template
// ============================================================================
// 배포 리소스:
//   - Virtual Network (3 Subnets)
//   - NSG (App / Collector)
//   - VM: App (Ubuntu 24.04 + Nginx)
//   - VM: Collector (Windows Server 2022)
//   - Application Gateway (Standard V2)
//   - Public IPs
// ============================================================================

@description('배포 리전')
param location string = resourceGroup().location

@description('App VM 관리자 사용자 이름')
param adminUsername string = 'azureuser'

@description('App VM (Linux) SSH 공개 키')
@secure()
param adminSshPublicKey string

@description('Collector VM (Windows) 관리자 비밀번호')
@secure()
param collectorAdminPassword string

@description('Collector VM 관리자 사용자 이름')
param collectorAdminUsername string = 'azureuser'

// ============================================================================
// Variables
// ============================================================================
var vnetName = 'vnet-vtap-lab'
var vnetAddressPrefix = '10.0.0.0/16'

var snetApp = {
  name: 'snet-app'
  addressPrefix: '10.0.1.0/24'
}
var snetCollector = {
  name: 'snet-collector'
  addressPrefix: '10.0.2.0/24'
}
var snetAgw = {
  name: 'snet-agw'
  addressPrefix: '10.0.3.0/24'
}

var appVmName = 'vm-app'
var collectorVmName = 'vm-collector'
var agwName = 'agw-vtap-lab'

// ============================================================================
// Network Security Groups
// ============================================================================
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgCollector 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-collector'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-VXLAN'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '4789'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// ============================================================================
// Virtual Network
// ============================================================================
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: snetApp.name
        properties: {
          addressPrefix: snetApp.addressPrefix
          networkSecurityGroup: { id: nsgApp.id }
        }
      }
      {
        name: snetCollector.name
        properties: {
          addressPrefix: snetCollector.addressPrefix
          networkSecurityGroup: { id: nsgCollector.id }
        }
      }
      {
        name: snetAgw.name
        properties: {
          addressPrefix: snetAgw.addressPrefix
        }
      }
    ]
  }
}

// ============================================================================
// Public IPs
// ============================================================================
resource pipApp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'pip-app'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource pipCollector 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'pip-collector'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource pipAgw 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'pip-agw'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// ============================================================================
// Network Interfaces
// ============================================================================
resource nicApp 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: '${appVmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: vnet.properties.subnets[0].id }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: pipApp.id }
        }
      }
    ]
  }
}

resource nicCollector 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: '${collectorVmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: vnet.properties.subnets[1].id }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: pipCollector.id }
        }
      }
    ]
  }
}

// ============================================================================
// App VM (Ubuntu 24.04)
// ============================================================================
resource vmApp 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: appVmName
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_D2as_v5' }
    osProfile: {
      computerName: appVmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
    }
    networkProfile: {
      networkInterfaces: [{ id: nicApp.id }]
    }
  }
}

// ============================================================================
// Collector VM (Windows Server 2022)
// ============================================================================
resource vmCollector 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: collectorVmName
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_D2as_v5' }
    osProfile: {
      computerName: collectorVmName
      adminUsername: collectorAdminUsername
      adminPassword: collectorAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
    }
    networkProfile: {
      networkInterfaces: [{ id: nicCollector.id }]
    }
  }
}

// ============================================================================
// Application Gateway (Standard V2)
// ============================================================================
resource agw 'Microsoft.Network/applicationGateways@2024-01-01' = {
  name: agwName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'agw-ip-config'
        properties: {
          subnet: { id: vnet.properties.subnets[2].id }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'agw-frontend-ip'
        properties: {
          publicIPAddress: { id: pipAgw.id }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port-80'
        properties: { port: 80 }
      }
    ]
    backendAddressPools: [
      {
        name: 'backend-pool-app'
        properties: {
          backendAddresses: [
            { ipAddress: nicApp.properties.ipConfigurations[0].properties.privateIPAddress }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'http-settings'
        properties: {
          port: 80
          protocol: 'Http'
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'http-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agwName, 'agw-frontend-ip')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agwName, 'port-80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routing-rule'
        properties: {
          priority: 100
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', agwName, 'http-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', agwName, 'backend-pool-app')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', agwName, 'http-settings')
          }
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================
output appVmPublicIp string = pipApp.properties.ipAddress
output collectorVmPublicIp string = pipCollector.properties.ipAddress
output appGatewayPublicIp string = pipAgw.properties.ipAddress
output appVmNicId string = nicApp.id
output collectorVmNicId string = nicCollector.id
