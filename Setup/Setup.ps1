#Requires -RunAsAdministrator
#Requires -PSEdition Core
#Requires -Version 7.2

param([switch]$RunNow)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$script:rootDir = Resolve-Path (Join-Path $PSScriptRoot ..)
$script:profileDir = Join-Path $rootDir Profile
. "$profileDir/Common.ps1"
. "$profileDir/Functions.ps1"

$script:setupControl = Join-Path $PSScriptRoot .setupran
$script:setupDir = $PSScriptRoot

function RunSetup {
    if (!(Test-Path $setupControl)) {
        New-Item -ItemType File "$setupControl" | Out-Null
        if ($IsWindows) { (Get-Item $setupControl).Attributes += 'Hidden' }
    }
    & "$setupDir/InstallModules.ps1"
    & "$setupDir/InstallTools.ps1"
    if ($IsWindows) {
        & "$setupDir/Setup-Windows.ps1"
    }
}

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced -or $RunNow) {
    RunSetup
}
