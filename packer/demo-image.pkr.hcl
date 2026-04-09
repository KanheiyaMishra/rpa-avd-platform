packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 2.0.0"
    }
  }
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "location" {
  type = string
}

variable "hub_resource_group" {
  type = string
}

variable "gallery_name" {
  type = string
}

variable "image_definition_name" {
  type = string
  default = "img-def-demo"
}

variable "image_version" {
  type = string
}

variable "build_vm_admin_username" {
  type    = string
  default = "packeradmin"
}

variable "build_vm_admin_password" {
  type      = string
  sensitive = true
}

source "azure-arm" "demo" {
  use_azure_cli_auth = true

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id

  os_type         = "Windows"
  location        = var.location
  vm_size         = "Standard_D4s_v5"

  managed_image_resource_group_name = var.hub_resource_group
  managed_image_name                = "mi-avd-demo-${replace(timestamp(), ":", "-")}"

  image_publisher = "MicrosoftWindowsDesktop"
  image_offer     = "windows-11"
  image_sku       = "win11-25h2-avd"
  image_version   = "latest"

  communicator     = "winrm"
  winrm_use_ssl    = true
  winrm_insecure   = true
  winrm_timeout    = "30m"
  winrm_username   = var.build_vm_admin_username
  winrm_password   = var.build_vm_admin_password

  azure_tags = {
    source = "packer"
    role   = "avd-demo-image-build"
  }

  shared_image_gallery_destination {
    resource_group      = var.hub_resource_group
    gallery_name        = var.gallery_name
    image_name          = var.image_definition_name
    image_version       = var.image_version
    replication_regions = [var.location]
  }
}

build {
  name    = "avd-demo-image"
  sources = ["source.azure-arm.demo"]

  provisioner "powershell" {
    execute_command = "powershell -ExecutionPolicy Bypass -File {{.Path}}"
    scripts         = ["../platform/images/install-demo.ps1"]
  }

  provisioner "powershell" {
    execute_command = "powershell -ExecutionPolicy Bypass -File {{.Path}}"
    scripts         = ["../platform/images/validate-demo-image.ps1"]
  }

  # Ensure the image is generalized before capture.
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep generalization...';",
      "Start-Process -FilePath $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe -ArgumentList '/oobe /generalize /shutdown /quiet' -Wait"
    ]
  }
}
