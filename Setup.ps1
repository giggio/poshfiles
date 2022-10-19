#Requires -RunAsAdministrator
#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

Push-Location $PSScriptRoot | Out-Null
git submodule update --init --recursive
Pop-Location

$script:setupDir = Join-Path $PSScriptRoot Setup
$script:profileDir = Join-Path $PSScriptRoot Profile
. "$profileDir/Common.ps1"
& "$setupDir/InstallModules.ps1"
& "$setupDir/InstallTools.ps1"

if ($IsWindows) {
    . "$setupDir/WindowsDefenderExclusions.ps1"
    Add-WindowsDefenderExclusions -Quiet
    . "$setupDir/Configure-Windows.ps1"

    $ssha = Get-Service ssh-agent -ErrorAction SilentlyContinue
    if ($null -ne $ssha) {
        if ($null -ne $env:SSH_AUTH_SOCK) {
            if ($ssha.StartType -eq 'Automatic') {
                Write-Output "Setting ssh-agent to manual."
                Set-Service $ssha -StartMode Manual
            }
        } else {
            if ($ssha.StartType -eq 'Manual') {
                Write-Output "Setting ssh-agent to automatic."
                Set-Service $ssha -StartMode Automatic
            }
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
$script:setupControl = Join-Path $PSScriptRoot .setupran
if (!(Test-Path $setupControl)) {
    New-Item -ItemType File "$setupControl" | Out-Null
    if ($IsWindows) { (Get-Item $setupControl).Attributes += 'Hidden' }
}
