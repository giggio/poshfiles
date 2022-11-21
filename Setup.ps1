#Requires -RunAsAdministrator

param([switch]$RunNow)

$ErrorActionPreference = 'Stop'

Set-StrictMode -Version 3.0
$script:profileDir = Join-Path $PSScriptRoot Profile
. "$profileDir/Common.ps1"
. "$profileDir/Functions.ps1"

$script:setupControl = Join-Path $PSScriptRoot .setupran
function RunSetup {
    $script:setupDir = Join-Path $PSScriptRoot Setup
    $script:profileDir = Join-Path $PSScriptRoot Profile
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
