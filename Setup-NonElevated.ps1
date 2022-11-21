#Requires -PSEdition Core
#Requires -Version 7.2

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (!$IsWindows) {
    Write-Warning "This script is only for Windows."
    exit
}

$script:profileDir = Join-Path $PSScriptRoot Profile
. "$profileDir/Functions.ps1"

if (Test-Elevated) {
    Write-Error "This script must not be run as administrator."
    exit 1
}

$script:setupDir = Join-Path $PSScriptRoot Setup
$script:setupControl = Join-Path $PSScriptRoot .setupran-nonelevated
function RunSetupNonElevated {
    Push-Location $PSScriptRoot | Out-Null
    git submodule update --init --recursive
    Pop-Location

    if ($IsWindows) {
        & "$setupDir/InstallTools-Windows-NonElevated.ps1"
    }
    if (!(Test-Path $setupControl)) {
        New-Item -ItemType File "$setupControl" | Out-Null
        if ($IsWindows) { (Get-Item $setupControl).Attributes += 'Hidden' }
    }
}

function CheckSetupNonElevated([switch]$BypassCheck = $false) {
    if (!(Test-Path $setupControl) -or $BypassCheck) {
        $script:setupControlDoNotRun = Join-Path $PSScriptRoot .setupdonotrun
        $script:setupControlForceRun = Join-Path $PSScriptRoot .setupforcerun
        if (!(Test-Path $setupControlDoNotRun )) {
            if (Test-Path $setupControlForceRun) {
                Remove-Item -Force $setupControlForceRun
                RunSetupNonElevated
            } else {
                $choices = @(
                    [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run setup (non elevated)")
                    [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run setup at this time")
                    [System.Management.Automation.Host.ChoiceDescription]::new("&Don't ask again", "Don't ask to run setup again")
                )
                $script:runSetup = $Host.UI.PromptForChoice("Run non-elevated setup?", "Setup has not ran yet, do you want to run it now?", $choices, 1)
                switch ($runSetup) {
                    0 {
                        RunSetupNonElevated
                    }
                    2 {
                        New-Item -ItemType File "$setupControlDoNotRun" | Out-Null
                        if ($IsWindows) { (Get-Item $setupControlDoNotRun).Attributes += 'Hidden' }
                        Write-Output "You will not be asked to run setup again. If you want to run it, run $(Join-Path $PSScriptRoot Setup-NonElevated.ps1), or delete the file '$setupControlDoNotRun' and restart PowerShell."
                    }
                    Default {}
                }
            }
        }
    }
}

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    CheckSetupNonElevated -BypassCheck
}
