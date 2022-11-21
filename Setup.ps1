#Requires -RunAsAdministrator

param([switch]$RunNow)

Set-StrictMode -Version 3.0
$script:profileDir = Join-Path $PSScriptRoot Profile
. "$profileDir/Common.ps1"
. "$profileDir/Functions.ps1"

$script:setupControl = Join-Path $PSScriptRoot .setupran
function RunSetup {
    $script:setupDir = Join-Path $PSScriptRoot Setup
    $script:profileDir = Join-Path $PSScriptRoot Profile
    & "$setupDir/InstallModules.ps1"
    & "$setupDir/InstallTools.ps1"

    if ($IsWindows) {
        Sync-Path
        . "$setupDir/WindowsDefenderExclusions.ps1"
        Add-WindowsDefenderExclusions
        . "$setupDir/Configure-Windows.ps1"

        & "$setupDir/wsl-ssh-pageant-installer/check-install.ps1"
        if (!$?) {
            & "$setupDir/wsl-ssh-pageant-installer/install.ps1"
            & "$setupDir/wsl-ssh-pageant-installer/start.ps1"
            $env:SSH_AUTH_SOCK = '\\.\pipe\ssh-pageant'
        }

        $ssha = Get-Service ssh-agent -ErrorAction SilentlyContinue
        if ($null -ne $ssha) {
            # set ssh-agent to start manually, as we're using wsl-ssh-pageant
            if ($ssha.StartType -ne 'Manual') {
                Write-Output "Setting ssh-agent to manual."
                Set-Service $ssha -StartMode Manual
            }
        }

        if (Test-Path "$env:ProgramFiles\Git\usr\bin") {
            # git tools
            if ($env:path.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0) {
                Write-Output "Setting local PATH to use Git tools."
                $env:PATH = "$env:PATH;$env:ProgramFiles\Git\usr\bin"
            }
            $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
            if ($machinePath.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0) {
                Write-Output "Setting machine PATH to use Git tools."
                [Environment]::SetEnvironmentVariable('PATH', "$machinePath;$env:ProgramFiles\Git\usr\bin", 'Machine')
            }
        }
    }
    if (!(Test-Path $setupControl)) {
        New-Item -ItemType File "$setupControl" | Out-Null
        if ($IsWindows) { (Get-Item $setupControl).Attributes += 'Hidden' }
    }
}

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced -or $RunNow) {
    RunSetup
}
