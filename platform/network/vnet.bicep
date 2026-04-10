targetScope = 'resourceGroup'

param location string
param vnetName string
param vnetAddressPrefix string = '10.0.0.0/16'
param subnetName string = 'avd-subnet'
param subnetAddressPrefix string = '10.0.1.0/24'
param nsgName string = 'avd-nsg'

// Network Security Group with rules for AVD
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 101
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          priority: 102
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
        }
      }
      {
        name: 'AllowDNS'
        properties: {
          priority: 103
          protocol: 'Udp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '53'
        }
      }
    ]
  }
}

// Route Table
resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: concat(vnetName, '-rt')
  location: location
  properties: {
    routes: [
      {
        name: 'DefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output subnetId string = concat(vnet.id, '/subnets/', subnetName)
output nsgId string = nsg.id
output routeTableId string = routeTable.id</content>
<parameter name="filePath">c:\github kanheiya\rpa-avd-platform\platform\network\vnet.bicep
