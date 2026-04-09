targetScope = 'subscription'
param location string
param hostPoolName string
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
 name: 'rg-avd-hub-${hostPoolName}'
 location: location
}
output rgName string = rg.name