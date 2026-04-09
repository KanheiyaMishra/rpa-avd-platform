# ============================================================
# Demo Golden Image - Full Software Suite
# Software: Edge, Chrome, Defender, O365, Adobe, 7-Zip,
#           OneDrive, SQL Client, RDC, Python, UiPath, WinSCP,
#           VSCode, Admin Tools
# Executed by Packer during golden image customization
# ============================================================

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$tempDir = 'C:\Temp\ImageSetup'
$bootstrapDir = 'C:\ProgramData\AVD'
$vscodeExtensions = @(
  'ms-python.python'
  'ms-toolsai.jupyter'
  'ms-mssql.mssql'
)

New-Item -ItemType Directory -Force -Path $tempDir, $bootstrapDir | Out-Null

function Invoke-CheckedProcess {
  param(
    [string] $FilePath,
    [string[]] $ArgumentList,
    [string] $Operation,
    [int[]] $AllowedExitCodes = @(0)
  )

  $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -Wait -PassThru -NoNewWindow
  if ($process.ExitCode -notin $AllowedExitCodes) {
    throw "$Operation failed with exit code $($process.ExitCode)."
  }
}

function Invoke-CheckedWingetInstall {
  param(
    [string] $PackageId,
    [string] $DisplayName = $PackageId
  )

  Write-Host "Installing $DisplayName..."
  & winget install --id $PackageId --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
  if ($LASTEXITCODE -ne 0) {
    throw "winget install failed for $DisplayName with exit code $LASTEXITCODE."
  }
}

function Set-RegistryValue {
  param(
    [string] $Path,
    [string] $Name,
    [object] $Value,
    [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord
  )

  if (-not (Test-Path $Path)) {
    New-Item -Path $Path -Force | Out-Null
  }

  New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Register-ActiveSetup {
  param(
    [string] $KeyName,
    [string] $StubPath,
    [string] $Version = '1,0'
  )

  $activeSetupPath = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$KeyName"
  if (-not (Test-Path $activeSetupPath)) {
    New-Item -Path $activeSetupPath -Force | Out-Null
  }

  New-ItemProperty -Path $activeSetupPath -Name '(Default)' -Value $KeyName -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $activeSetupPath -Name 'StubPath' -Value $StubPath -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $activeSetupPath -Name 'Version' -Value $Version -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $activeSetupPath -Name 'IsInstalled' -Value 1 -PropertyType DWord -Force | Out-Null
}

Write-Host 'Ensuring winget is available...'
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction SilentlyContinue
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw 'winget is not available on the build VM.'
}

Invoke-CheckedWingetInstall -PackageId 'Microsoft.Edge' -DisplayName 'Microsoft Edge'
Invoke-CheckedWingetInstall -PackageId 'Google.Chrome' -DisplayName 'Google Chrome'

Write-Host 'Updating Microsoft Defender signatures...'
Update-MpSignature -ErrorAction SilentlyContinue

Write-Host 'Installing Microsoft 365 Apps with Shared Computer Activation...'
$odtUrl = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17928-20156.exe'
$odtExe = Join-Path $tempDir 'odt.exe'
Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe -UseBasicParsing
Invoke-CheckedProcess -FilePath $odtExe -ArgumentList @("/quiet", "/extract:$tempDir\ODT") -Operation 'Extract Office Deployment Tool'

$odtConfig = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise">
  <Product ID="O365ProPlusRetail">
    <Language ID="en-us" />
    <ExcludeApp ID="Teams" />
  </Product>
  </Add>
  <Property Name="SharedComputerLicensing" Value="1" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Updates Enabled="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@

$odtConfigPath = Join-Path $tempDir 'ODT\config.xml'
$odtConfig | Out-File $odtConfigPath -Encoding utf8
Invoke-CheckedProcess -FilePath (Join-Path $tempDir 'ODT\setup.exe') -ArgumentList @('/configure', $odtConfigPath) -Operation 'Install Microsoft 365 Apps'

Invoke-CheckedWingetInstall -PackageId 'Adobe.Acrobat.Reader.64-bit' -DisplayName 'Adobe Acrobat Reader'
Invoke-CheckedWingetInstall -PackageId '7zip.7zip' -DisplayName '7-Zip'

Write-Host 'Installing Microsoft OneDrive...'
$oneDriveUrl = 'https://go.microsoft.com/fwlink/?linkid=844652'
$oneDriveInstaller = Join-Path $tempDir 'OneDriveSetup.exe'
Invoke-WebRequest -Uri $oneDriveUrl -OutFile $oneDriveInstaller -UseBasicParsing
Invoke-CheckedProcess -FilePath $oneDriveInstaller -ArgumentList @('/allusers') -Operation 'Install Microsoft OneDrive'

$oneDrivePolicyRoot = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
Set-RegistryValue -Path $oneDrivePolicyRoot -Name 'SilentAccountConfig' -Value 1
Set-RegistryValue -Path $oneDrivePolicyRoot -Name 'FilesOnDemandEnabled' -Value 1
Set-RegistryValue -Path $oneDrivePolicyRoot -Name 'DisableTutorial' -Value 1

Invoke-CheckedWingetInstall -PackageId 'Microsoft.SQLServerManagementStudio' -DisplayName 'SQL Server Management Studio'
Write-Host 'Remote Desktop Connection is built-in on Windows 11.'
Invoke-CheckedWingetInstall -PackageId 'Python.Python.3.12' -DisplayName 'Python'

Write-Host 'Installing UiPath Studio...'
$uipathInstaller = Join-Path $tempDir 'UiPathStudio.msi'
Invoke-WebRequest -Uri 'https://download.uipath.com/UiPathStudio.msi' -OutFile $uipathInstaller -UseBasicParsing
Invoke-CheckedProcess -FilePath 'msiexec.exe' -ArgumentList @('/i', $uipathInstaller, '/quiet', '/norestart', 'ADDLOCAL=DesktopFeature,Studio,RobotFeature,RegisterService') -Operation 'Install UiPath Studio'

Invoke-CheckedWingetInstall -PackageId 'WinSCP.WinSCP' -DisplayName 'WinSCP'
Invoke-CheckedWingetInstall -PackageId 'Microsoft.VisualStudioCode' -DisplayName 'Visual Studio Code'

Write-Host 'Installing RSAT Admin Tools...'
$rsatCapabilities = @(
  'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0'
  'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0'
  'Rsat.Dns.Tools~~~~0.0.1.0'
  'Rsat.DHCP.Tools~~~~0.0.1.0'
  'Rsat.ServerManager.Tools~~~~0.0.1.0'
)
foreach ($capability in $rsatCapabilities) {
  Add-WindowsCapability -Online -Name $capability | Out-Null
}

$userBootstrapScript = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$vscodePath = "${env:ProgramFiles}\Microsoft VS Code\bin\code.cmd"
if (Test-Path `$vscodePath) {
  `$extensions = @(
    'ms-python.python'
    'ms-toolsai.jupyter'
    'ms-mssql.mssql'
  )
  foreach (`$extension in `$extensions) {
    & `$vscodePath --install-extension `$extension --force --user-data-dir "`$env:LOCALAPPDATA\Programs\Microsoft VS Code\User Data" | Out-Null
  }
}

`$oneDrivePaths = @(
  "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
  "$env:ProgramFiles(x86)\Microsoft OneDrive\OneDrive.exe"
)
foreach (`$oneDrivePath in `$oneDrivePaths) {
  if (Test-Path `$oneDrivePath) {
    Start-Process -FilePath `$oneDrivePath -ArgumentList '/background' -WindowStyle Hidden
    break
  }
}

`$uiPathAssistant = "$env:ProgramFiles\UiPath\Studio\UiPath Assistant.exe"
if (Test-Path `$uiPathAssistant) {
  Start-Process -FilePath `$uiPathAssistant -WindowStyle Minimized
}
"@

$userBootstrapPath = Join-Path $bootstrapDir 'Initialize-UserProfile.ps1'
$userBootstrapScript | Out-File $userBootstrapPath -Encoding utf8

Register-ActiveSetup -KeyName 'AVD-UserBootstrap' -StubPath "powershell.exe -ExecutionPolicy Bypass -File `"$userBootstrapPath`"" -Version '1,0'

Write-Host 'Cleaning up temp files...'
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host 'Demo image setup complete. All software installed successfully.'
