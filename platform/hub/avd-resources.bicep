targetScope = 'resourceGroup'
param location string
param hostPoolName string
param workspaceName string

// Demo host pool (Pooled - shared desktop environment)
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
 name: hostPoolName
 location: location
 properties: {
   hostPoolType: 'Pooled'
   loadBalancerType: 'DepthFirst'
   preferredAppGroupType: 'Desktop'
   description: 'Demo host pool - Full desktop AVD environment'
 }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
 name: workspaceName
 location: location
}

// Desktop app group for demo users (full desktop access)
resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
 name: '${hostPoolName}-dag'
 location: location
 properties: {
   hostPoolArmPath: hostPool.id
   applicationGroupType: 'Desktop'
   description: 'Desktop group for demo AVD environment'
 }
}

output hostPoolName string = hostPool.name
output appGroupName string = appGroup.name
output workspaceName string = workspace.name
