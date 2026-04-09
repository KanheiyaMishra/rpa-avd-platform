targetScope = 'resourceGroup'

param location string
param galleryName string

resource gallery 'Microsoft.Compute/galleries@2023-07-03' = {
  name: galleryName
  location: location
}

resource imageDefDemo 'Microsoft.Compute/galleries/images@2023-07-03' = {
  parent: gallery
  name: 'img-def-demo'
  location: location
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    hyperVGeneration: 'V2'
    architecture: 'x64'
    identifier: {
      publisher: 'FAITInfrastructure'
      offer: 'Windows11-AVD'
      sku: 'demo'
    }
    recommended: {
      vCPUs: {
        min: 4
        max: 16
      }
      memory: {
        min: 16
        max: 64
      }
    }
    description: 'Demo image: Edge, Chrome, Defender, O365, Adobe, 7-Zip, OneDrive, SQL Client, RDC, Python, UiPath, WinSCP, VSCode, Admin Tools'
  }
}

output galleryId string = gallery.id
output demoImageDefId string = imageDefDemo.id
