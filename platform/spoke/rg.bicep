targetScope = 'subscription'
param location string
param resourceGroupName string
resource spokeRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
 name: resourceGroupName
 location: location
}