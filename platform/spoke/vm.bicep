targetScope = 'resourceGroup'
param location string
param hostPoolName string
param registrationToken string
param vmName string
param adminUsername string
@secure()
param adminPassword string
param subnetId string

// Set imageSource to 'gallery' to use a custom golden image, or 'marketplace' for default Windows 11 AVD
@allowed(['gallery', 'marketplace'])
param imageSource string = 'marketplace'
param galleryImageId string = '' // Required when imageSource is 'gallery'

var configArtifactUri = 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/Configuration.zip'
var extensionCommand = 'powershell -ExecutionPolicy Unrestricted -Command "New-Item -ItemType Directory -Path C:\\temp -Force | Out-Null; Invoke-WebRequest -Uri ${configArtifactUri} -OutFile C:\\temp\\avd.zip; Expand-Archive -Path C:\\temp\\avd.zip -DestinationPath C:\\temp\\avd -Force; C:\\temp\\avd\\Configuration.ps1 -HostPoolName ${hostPoolName} -RegistrationToken ${registrationToken}"'

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
 name: '${vmName}-nic'
 location: location
 properties: {
   ipConfigurations: [
     {
       name: 'ipconfig1'
       properties: {
         subnet: {
           id: subnetId
         }
         privateIPAllocationMethod: 'Dynamic'
       }
     }
   ]
 }
}
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
 name: vmName
 location: location
 properties: {
   hardwareProfile: {
     vmSize: 'Standard_D4s_v5'
   }
   osProfile: {
     computerName: vmName
     adminUsername: adminUsername
     adminPassword: adminPassword
   }
   storageProfile: {
     imageReference: imageSource == 'gallery' ? {
       id: galleryImageId
     } : {
       publisher: 'MicrosoftWindowsDesktop'
       offer: 'windows-11'
       sku: 'win11-25h2-avd'
       version: 'latest'
     }
     osDisk: {
       createOption: 'FromImage'
     }
   }
   networkProfile: {
     networkInterfaces: [
       {
         id: nic.id
       }
     ]
   }
 }
}

resource avdExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
 parent: vm
 name: 'avdAgent'
 location: location
 properties: {
   publisher: 'Microsoft.Compute'
   type: 'CustomScriptExtension'
   typeHandlerVersion: '1.10'
   autoUpgradeMinorVersion: true
   protectedSettings: {
     commandToExecute: extensionCommand
   }
 }
}
