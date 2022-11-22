#Requires -PSEdition Core
#Requires -Version 7.2

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (!$IsWindows) {
    Write-Warning "This script is only for Windows."
    exit
}

$script:rootDir = Resolve-Path (Join-Path $PSScriptRoot ..)
$script:profileDir = Join-Path $rootDir Profile
. "$profileDir/Functions.ps1"

if (Test-Elevated) {
    Write-Error "This script must not be run as administrator."
    exit 1
}

$script:setupDir = $PSScriptRoot
$script:setupControl = Join-Path $PSScriptRoot .setupran-nonelevated
function RunSetupNonElevated {
    Push-Location $rootDir | Out-Null
    git submodule update --init --recursive
    Pop-Location
    if (!(Test-Path $setupControl)) {
        New-Item -ItemType File "$setupControl" | Out-Null
        if ($IsWindows) { (Get-Item $setupControl).Attributes += 'Hidden' }
    }
    if ($IsWindows) {
        & "$setupDir/InstallTools-Windows-NonElevated.ps1"
    }
    . "$setupDir/InstallModules.ps1"
}

function CheckSetupNonElevated([switch]$BypassCheck = $false) {
    if (!(Test-Path $setupControl) -or $BypassCheck) {
        $script:setupControlDoNotRun = Join-Path $PSScriptRoot .setupdonotrun
        if (!(Test-Path $setupControlDoNotRun)) {
            $choices = @(
                [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run setup (non elevated)")
                [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run setup at this time")
                [System.Management.Automation.Host.ChoiceDescription]::new("&Don't ask again", "Don't ask to run setup again")
            )
            $script:runSetup = $Host.UI.PromptForChoice("Run non-elevated setup?", "Setup has not ran yet, do you want to run it now?", $choices, 1)
            switch ($runSetup) {
                0 {
                    RunSetupNonElevated
                    Sync-Path
                }
                2 {
                    New-Item -ItemType File "$setupControlDoNotRun" | Out-Null
                    if ($IsWindows) { (Get-Item $setupControlDoNotRun).Attributes += 'Hidden' }
                    Write-Output "You will not be asked to run setup again. If you want to run it, run $PSCommandPath, or delete the file '$setupControlDoNotRun' and restart PowerShell."
                }
                Default {}
            }
        }
    }
    . "$PSScriptRoot/Setup-Check.ps1"
    CheckSetup
}

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    CheckSetupNonElevated -BypassCheck
}
