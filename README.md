# AVD Platform IaC  
**Azure Virtual Desktop Infrastructure as Code — Hub-and-Spoke topology with Packer-built golden images and GitHub Actions automation**

---

## 📋 Overview

This repository deploys a complete **Azure Virtual Desktop (AVD)** platform using:
- **Bicep** templates for infrastructure (hub/spoke, host pools, workspaces, app groups, compute gallery)
- **Packer HCL** for golden image builds with pre-installed software
- **GitHub Actions** workflows for infrastructure, image builds, and session host scaling
- **Azure Compute Gallery** for centralized golden image management

The platform is designed for **demo/RPA scenarios** with a single pooled host pool and desktop application group, enabling users to log in and immediately access a pre-configured Windows 11 AVD desktop with all required software.

---

## 🏗️ Architecture: Hub-and-Spoke Topology

```
┌─────────────────────────────────────┐
│         HUB Resource Group          │
├─────────────────────────────────────┤
│ • Compute Gallery (acg_avd_dev)     │
│ • Host Pool (hp-demo)               │
│ • Workspace (ws-demo)               │
│ • Desktop App Group (dag)           │
│ • Image Definitions (img-def-demo)  │
└─────────────────────────────────────┘
           ↓ (association)
┌─────────────────────────────────────┐
│       SPOKE Resource Group          │
├─────────────────────────────────────┤
│ • Session Hosts (avd-demo-01, ..N)  │
│ • NICs (network interfaces)          │
│ • AVD Extension (registration)      │
└─────────────────────────────────────┘
```

**Rationale:**
- **Hub** = Central AVD management resources (gallery, host pool, workspace)
- **Spoke** = Session host VMs isolated in separate RG for compute scaling
- **Gallery** = Centralized golden image versioning and replication

---

## 🎯 What Gets Deployed

### Infrastructure (Run Once)
- Resource groups for hub and spoke
- Azure Compute Gallery with image definitions
- AVD Host Pool (pooled, depth-first load balancing)
- AVD Workspace
- Desktop Application Group (full desktop access)
- Workspace-to-AppGroup association

### Golden Image (Build & Publish)
Pre-installed software on Windows 11 AVD base image:
- **Browsers:** Microsoft Edge, Google Chrome
- **Office:** Microsoft 365 Apps (with Shared Computer Activation)
- **Cloud:** Microsoft OneDrive (with silent sign-in policy)
- **Developer Tools:** Visual Studio Code (with extensions: Python, Jupyter, SQL), Python 3.12, WinSCP, SQL Server Management Studio
- **Utilities:** Adobe Reader, 7-Zip, Remote Desktop Connection (built-in)
- **Admin Tools:** RSAT (Active Directory, Group Policy, DNS, DHCP, Server Manager)
- **RPA:** UiPath Studio (with Desktop, Studio, Robot, RegisterService features)
- **Defender:** Windows Defender with updated signatures

### Session Hosts (Scale as Needed)
- N session hosts deployed in parallel via GitHub Actions matrix
- Auto-registered to host pool using registration token
- Cloned from latest golden image in Compute Gallery

---

## 📁 Repository Structure

```
avd-platform-iac/
├── README.md                                    # This file
├── platform/
│   ├── hub/
│   │   ├── main.bicep                          # Hub RG creation (subscription scope)
│   │   ├── avd-resources.bicep                 # Host pool, workspace, app group
│   │   ├── gallery.bicep                       # Compute gallery + image definitions
│   │   └── association.bicep                   # Workspace-to-AppGroup link
│   ├── spoke/
│   │   ├── rg.bicep                            # Spoke RG creation
│   │   └── vm.bicep                            # VM, NIC, AVD extension registration
│   └── images/
│       ├── install-demo.ps1                    # Master install script (run in Packer)
│       └── validate-demo-image.ps1             # Smoke test (run before sysprep)
├── packer/
│   └── demo-image.pkr.hcl                      # Packer HCL template (build → gallery)
└── .github/workflows/
    ├── deploy-infrastructure.yml               # Create hub + spoke + gallery (first-time)
    ├── build-golden-image.yml                  # Build image via Packer, publish to gallery
    ├── deploy-session-hosts.yml                # Deploy N VMs from gallery image
    ├── rotate-registration-token.yml           # Refresh host pool registration token
    └── validate-packer.yml                     # PR validation for Packer template
```

---

## 🔄 Workflow Execution Order

**These workflows are independent; run them in this sequence:**

| Step | Workflow | When | Estimated Time |
|------|----------|------|-----------------|
| **1** | 🏗️ **Deploy AVD Infrastructure** | First-time setup only | ~5–10 min |
| **2** | 🖼️ **Build Demo Golden Image** | Before first session hosts, or when software changes | ~20–30 min |
| **3** | 💻 **Deploy Session Hosts** | To add/scale VMs (can repeat) | ~5–10 min per batch |
| *Optional* | 🔑 **Rotate Registration Token** | Weekly or before deployments | ~1 min |

---

## ⚙️ Setup Prerequisites

### 1. Azure Resources & OIDC
- **Azure subscription** with sufficient quota (D4s VMs, storage, compute gallery)
- **Microsoft Entra ID (Azure AD) Service Principal** for GitHub OIDC authentication
- Federated credential configured for GitHub Actions

### 2. GitHub Secrets (Required)
Set these in **Settings → Secrets and variables → Actions**:

```
AZURE_CLIENT_ID              → Service principal client ID
AZURE_TENANT_ID              → Azure AD tenant ID
AZURE_SUBSCRIPTION_ID        → Target subscription ID
PACKER_BUILD_VM_PASSWORD     → Temporary password for Packer build VM (WinRM)
AVD_VM_ADMIN_PASSWORD        → Local admin password for deployed session host VMs
```

### 3. GitHub Environment Variables (Required)
Set these in **Settings → Environments → dev** (or your environment name):

```
LOCATION               = eastus2                    # Azure region
HOST_POOL_NAME         = hp-demo                    # Host pool name
WORKSPACE_NAME         = ws-demo                    # Workspace name
GALLERY_NAME           = acg_avd_dev                # Compute gallery name
SPOKE_RG_NAME          = rg-avd-spoke-demo         # Session host RG name
HUB_RG_NAME            = rg-avd-hub-hp-demo        # Hub RG name (derived from HOST_POOL_NAME)
SUBNET_ID              = /subscriptions/.../subnets/subnet-name  # Target subnet for VMs
KEY_VAULT_NAME         = kvd-avd-demo              # For registration token storage (optional)
```

---

## 🚀 Running the Workflows

### 1️⃣ Deploy Infrastructure (First-Time Only)

**GitHub UI Path:** Actions → 🏗️ Deploy AVD Infrastructure → Run workflow

**Inputs:**
- **environment:** `dev` (or `prod`)
- **what_if:** `true` (preview changes) or `false` (deploy)

**What it does:**
1. Validates all Bicep templates (`bicep build`)
2. Previews infrastructure changes (optional what-if stage)
3. Creates hub RG with gallery + host pool + workspace + app group
4. Creates spoke RG for session hosts
5. Associates app group to workspace

**Example:**
```
Environment: dev
What-If: true          # Preview first
```

---

### 2️⃣ Build Golden Image

**GitHub UI Path:** Actions → 🖼️ Build Demo Golden Image (Packer) → Run workflow

**Inputs:**
- **environment:** `dev`
- **image_version:** `1.0.0` (semver format: X.Y.Z)

**What it does:**
1. Installs Packer from HashiCorp
2. Validates Packer HCL template
3. Spins up temporary D4s VM in Azure
4. Runs `install-demo.ps1` (installs all software)
5. Runs `validate-demo-image.ps1` (smoke test)
6. Runs Sysprep (generalize)
7. Captures image to Compute Gallery with version tag

**Example:**
```
Environment: dev
Image Version: 1.0.0
```

**Output:** Image version `1.0.0` available in Compute Gallery

---

### 3️⃣ Deploy Session Hosts

**GitHub UI Path:** Actions → 💻 Deploy Session Hosts → Run workflow

**Inputs:**
- **environment:** `dev`
- **vm_count:** `3` (number of VMs to deploy, 1–20)
- **image_version:** `latest` (or specific version like `1.0.0`)

**What it does:**
1. Auto-discovers last existing VM suffix in spoke RG
2. Generates fresh registration token (4-hour validity)
3. Builds dynamic VM matrix (e.g., avd-demo-01, avd-demo-02, avd-demo-03)
4. Deploys VMs **in parallel** using GitHub matrix strategy
5. Each VM automatically registers to host pool

**Example:**
```
Environment: dev
VM Count: 3
Image Version: latest
```

**Output:** 3 new VMs (avd-demo-01, avd-demo-02, avd-demo-03) deployed and registered

**Auto-Discovery Logic:**
- Queries spoke RG for existing `avd-demo-*` VMs
- Finds highest numeric suffix (e.g., if avd-demo-10 exists, starts at 11)
- Prevents naming conflicts automatically

---

### 4️⃣ Rotate Registration Token (Optional)

**GitHub UI Path:** Actions → 🔑 Rotate Registration Token → Run workflow

**Inputs:**
- **environment:** `dev`

**What it does:**
1. Generates new 48-hour registration token for host pool
2. Stores token in Azure Key Vault (secret name: `avd-reg-token-demo`)
3. Logs completion

**Example:**
```
Environment: dev
```

**Note:** This runs automatically every Sunday at 4am UTC, but can also be triggered manually.

---

## 🖥️ First-Logon Behavior: How Software Gets Ready

### During Image Build
1. **Packer spins up build VM** → runs `install-demo.ps1`
2. **Software installs** with fail-fast validation: Edge, Chrome, O365, OneDrive, VS Code, Python, UiPath, etc.
3. **Registry policies set** for Office (Shared Computer Activation), OneDrive (silent sign-in)
4. **Per-user bootstrap script created** → `C:\ProgramData\AVD\Initialize-UserProfile.ps1`
5. **Active Setup registration** → Bootstrap is registered to run once per new user at logon
6. **Smoke test runs** → Validates all software is present and policies are set
7. **Sysprep generalizes** → Image captured to gallery

### When User Logs In
1. **Active Setup trigger:** OS runs bootstrap script once per new user
2. **VS Code extensions install** (Python, Jupyter, SQL) in user context
3. **OneDrive starts** in background (`/background` flag, no popup)
4. **UiPath Assistant launches** minimized (attended automation UI)
5. **User gets full Windows 11 desktop** with all software ready

**Result:** Software is available immediately; no manual installation or reboots needed.

---

## 📊 Image Versioning Strategy

```
1.0.0  → Initial release (Edge, Chrome, O365, etc.)
1.0.1  → Office update or patch
1.1.0  → New software added (e.g., UiPath version bump)
2.0.0  → Major breaking change (e.g., base image OS upgrade)
```

**Deployment approach:**
- Old VMs continue to use their image version
- New VMs deploy with latest/specified version
- Side-by-side versions coexist in Compute Gallery

---

## 🔍 Key Files & Their Purposes

| File | Purpose | Runs When |
|------|---------|-----------|
| `platform/hub/main.bicep` | Hub RG creation | Deploy Infrastructure |
| `platform/hub/avd-resources.bicep` | Host pool + workspace + app group | Deploy Infrastructure |
| `platform/hub/gallery.bicep` | Compute Gallery + image definitions | Deploy Infrastructure |
| `platform/spoke/vm.bicep` | Session host VM + NIC + extension | Deploy Session Hosts |
| `platform/images/install-demo.ps1` | Software installation (baked into image) | Build Golden Image |
| `platform/images/validate-demo-image.ps1` | Post-install smoke test | Build Golden Image (before sysprep) |
| `packer/demo-image.pkr.hcl` | Packer build orchestration | Build Golden Image |
| `.github/workflows/deploy-infrastructure.yml` | Deploy infra workflow | Manual trigger |
| `.github/workflows/build-golden-image.yml` | Build image workflow | Manual trigger |
| `.github/workflows/deploy-session-hosts.yml` | Deploy hosts workflow | Manual trigger |

---

## 🛠️ Troubleshooting

### "Image not found in gallery"
**Cause:** Image version hasn't been built yet.  
**Fix:** Run "Build Demo Golden Image" workflow first with `image_version=1.0.0`.

### "VM deployment fails with registration error"
**Cause:** Registration token expired (valid 4 hours only).  
**Fix:** Run "Deploy Session Hosts" again with fresh token generation.

### "Packer build times out (WinRM)"
**Cause:** Build VM cannot be reached via WinRM.  
**Fix:** Check `PACKER_BUILD_VM_PASSWORD` is set correctly in GitHub Secrets.

### "Active Setup bootstrap doesn't run"
**Cause:** New user hasn't logged in yet, or bootstrap script path is invalid.  
**Fix:** Log in to a deployed VM as a new user; Active Setup runs once per new logon.

### "UiPath Assistant starts but shows error"
**Cause:** UiPath tenant/orchestrator not configured (expected behavior).  
**Fix:** Configure UiPath connection settings manually in Assistant, or update `install-demo.ps1` with tenant automation.

---

## 📝 Next Steps

1. **Set GitHub Secrets & Environment Variables** (see Setup Prerequisites above)
2. **Run Deploy Infrastructure** workflow (wait for completion)
3. **Run Build Golden Image** workflow with `image_version=1.0.0` (wait ~20–30 min)
4. **Run Deploy Session Hosts** workflow with `vm_count=1–5` and `image_version=1.0.0`
5. **Log in to AVD** from your client and verify software is present

---

## 📚 References

- [Azure Virtual Desktop Documentation](https://learn.microsoft.com/en-us/azure/virtual-desktop/)
- [Bicep Language](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Packer Azure Builder](https://developer.hashicorp.com/packer/integrations/hashicorp/azure)
- [GitHub Actions OIDC Authentication](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

## 📧 Support

For issues or questions:
1. Check the **Troubleshooting** section above
2. Review workflow run logs in **GitHub Actions**
3. Check Azure resource deployment status in **Azure Portal**
