$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-PathExists {
    param(
        [string] $Path,
        [string] $Description
    )

    if (-not (Test-Path $Path)) {
        throw "$Description not found at $Path."
    }
}

function Assert-InstalledDisplayName {
    param(
        [string] $Pattern,
        [string] $Description
    )

    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $match = Get-ItemProperty -Path $roots -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match $Pattern } |
        Select-Object -First 1

    if (-not $match) {
        throw "$Description is not registered as installed."
    }
}

function Assert-RegistryValue {
    param(
        [string] $Path,
        [string] $Name,
        [string] $ExpectedValue,
        [string] $Description
    )

    $currentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
    if ([string]$currentValue -ne $ExpectedValue) {
        throw "$Description expected '$ExpectedValue' but found '$currentValue'."
    }
}

Assert-PathExists -Path "$env:ProgramFiles (x86)\Microsoft\Edge\Application\msedge.exe" -Description 'Microsoft Edge'
Assert-PathExists -Path "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" -Description 'Google Chrome'
Assert-PathExists -Path "$env:SystemRoot\System32\mstsc.exe" -Description 'Remote Desktop Connection'
Assert-PathExists -Path "$env:ProgramFiles\Microsoft VS Code\Code.exe" -Description 'Visual Studio Code'

Assert-InstalledDisplayName -Pattern 'Microsoft 365 Apps' -Description 'Microsoft 365 Apps'
Assert-InstalledDisplayName -Pattern 'Adobe Acrobat Reader' -Description 'Adobe Acrobat Reader'
Assert-InstalledDisplayName -Pattern '7-Zip' -Description '7-Zip'
Assert-InstalledDisplayName -Pattern 'SQL Server Management Studio' -Description 'SQL Server Management Studio'
Assert-InstalledDisplayName -Pattern 'Python 3\.12' -Description 'Python 3.12'
Assert-InstalledDisplayName -Pattern 'WinSCP' -Description 'WinSCP'
Assert-InstalledDisplayName -Pattern 'UiPath' -Description 'UiPath'

Assert-PathExists -Path "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe" -Description 'Microsoft OneDrive'
Assert-PathExists -Path 'C:\ProgramData\AVD\Initialize-UserProfile.ps1' -Description 'User bootstrap script'

Assert-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'SilentAccountConfig' -ExpectedValue '1' -Description 'OneDrive silent sign-in policy'
Assert-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'FilesOnDemandEnabled' -ExpectedValue '1' -Description 'OneDrive Files On-Demand policy'
Assert-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'DisableTutorial' -ExpectedValue '1' -Description 'OneDrive tutorial suppression policy'

Assert-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -Name 'SharedComputerLicensing' -ExpectedValue '1' -Description 'Office shared computer activation setting'

$activeSetupPath = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\AVD-UserBootstrap'
Assert-PathExists -Path $activeSetupPath -Description 'Active Setup bootstrap registration'

$rsatCapabilities = @(
    'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0'
    'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0'
    'Rsat.Dns.Tools~~~~0.0.1.0'
    'Rsat.DHCP.Tools~~~~0.0.1.0'
    'Rsat.ServerManager.Tools~~~~0.0.1.0'
)
foreach ($capability in $rsatCapabilities) {
    $state = (Get-WindowsCapability -Online -Name $capability).State
    if ($state -ne 'Installed') {
        throw "Windows capability $capability is not installed."
    }
}

Write-Host 'Golden image smoke test passed.'