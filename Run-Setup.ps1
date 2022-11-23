param ([switch]$Force)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:setupDir = Join-Path $PSScriptRoot Setup
$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    if ($Force) {
        if (Test-Path $setupDir/.setupran) {
            Remove-Item $setupDir/.setupran -Force
        }
        if (Test-Path $setupDir/.setupran-nonelevated) {
            Remove-Item $setupDir/.setupran-nonelevated -Force
        }
        if (Test-Path $setupDir/.setupdonotrun) {
            Remove-Item $setupDir/.setupdonotrun -Force
        }
    }
}

$script:profileDir = Join-Path $PSScriptRoot Profile
. "$profileDir/Functions.ps1"
if (Test-Elevated) {
    if ($PSEdition -eq 'Core') {
        . "$PSScriptRoot/Setup/Setup-Check.ps1"
        CheckSetup
    } else {
        . "$PSScriptRoot/Setup/Setup-Bootstrap.ps1"
        if ($null -eq (Get-Command pwsh -ErrorAction SilentlyContinue)) {
            Write-Warning "PowerShell Core is not available and Setup cannot run. Install it from https://aka.ms/PSWindows, and then start PowerShell again."
        } else {
            pwsh.exe -Command ". `"$PSScriptRoot/Setup/Setup-Check.ps1`"; CheckSetup"
            Test-Error
            Sync-Path
        }
    }
} else {
    if ($PSEdition -eq 'Core') {
        . "$PSScriptRoot/Setup/Setup-NonElevated.ps1"
        CheckSetupNonElevated
    } else {
        . "$PSScriptRoot/Setup/Setup-Bootstrap.ps1"
        if ($null -eq (Get-Command pwsh -ErrorAction SilentlyContinue)) {
            Write-Warning "PowerShell Core is not available and Setup cannot run. Install it from https://aka.ms/PSWindows, and then start PowerShell again."
        } else {
            pwsh.exe -Command ". `"$PSScriptRoot/Setup/Setup-NonElevated.ps1`"; CheckSetupNonElevated"
            Test-Error
            Sync-Path
        }
    }
}
if (Test-Path Function:\CheckSetup) {
    Remove-Item -Path Function:\CheckSetup
}
if (Test-Path Function:\CheckSetupNonElevated) {
    Remove-Item -Path Function:\CheckSetupNonElevated
}
if (Test-Path Function:\RunSetupNonElevated) {
    Remove-Item -Path Function:\RunSetupNonElevated
}
if (Test-Path Function:\RunSetup) {
    Remove-Item -Path Function:\RunSetup
}
