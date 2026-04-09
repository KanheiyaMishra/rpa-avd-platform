targetScope = 'resourceGroup'
param hostPoolName string
param workspaceName string
param location string

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' existing = {
 name: '${hostPoolName}-dag'
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' existing = {
 name: workspaceName
}

resource workspaceUpdate 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' = {
 name: workspace.name
 location: location
 properties: {
   applicationGroupReferences: [
     appGroup.id
   ]
 }
}
