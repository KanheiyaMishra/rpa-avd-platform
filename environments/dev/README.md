# Development Environment Configuration

This folder contains parameter reference files for the AVD platform development environment. These files document the expected configuration values used by workflows.

## 📝 File Structure

- **`infrastructure.json`** — Hub and spoke infrastructure parameters (host pool, workspace, gallery)
- **`image-build.json`** — Packer image build parameters (image definitions, versions)
- **`session-hosts.json`** — Session host deployment parameters (VM sizing, naming, count)

## 🔗 How These Are Used

**Current Approach:** Workflows currently use GitHub Environment Variables (set in repo settings) instead of these files, as they are more secure and flexible for CI/CD.

**These files serve as:**
- 📖 Reference documentation for team members
- 🎯 Parameter templates for future templating or local testing
- ✅ Version control-friendlier way to track configuration

## 🚀 Setting Up Dev Environment

1. **Configure GitHub Secrets** (Settings → Secrets and variables → Actions):
   ```
   AZURE_CLIENT_ID
   AZURE_TENANT_ID
   AZURE_SUBSCRIPTION_ID
   PACKER_BUILD_VM_PASSWORD
   AVD_VM_ADMIN_PASSWORD
   ```

2. **Configure GitHub Environment Variables** (Settings → Environments → dev):
   ```
   LOCATION=eastus2
   HOST_POOL_NAME=hp-demo
   WORKSPACE_NAME=ws-demo
   GALLERY_NAME=acg_avd_dev
   SPOKE_RG_NAME=rg-avd-spoke-demo
   HUB_RG_NAME=rg-avd-hub-hp-demo
   VNET_NAME=vnet-avd-demo
   SUBNET_NAME=avd-subnet
   NSG_NAME=avd-nsg
   KEY_VAULT_NAME=kvd-avd-demo
   ```

3. **Run workflows in sequence:**
   - Deploy Infrastructure
   - Build Golden Image
   - Deploy Session Hosts

## 📋 Parameter Reference

See individual JSON files for exact parameter specifications and defaults.
