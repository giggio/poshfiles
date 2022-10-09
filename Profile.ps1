Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:profileDir = Join-Path $PSScriptRoot Profile
. "$profileDir/Common.ps1"
if ($IsWindows -and $null -eq $env:HOME -and $null -ne $env:USERPROFILE) {
    $env:HOME = $env:USERPROFILE
}
. "$profileDir/Functions.ps1"

if (!(Test-Path (Join-Path $PSScriptRoot .setupran))) {
    $script:setupControlDoNotRun = Join-Path $PSScriptRoot .setupdonotrun
    $script:setupControlForceRun = Join-Path $PSScriptRoot .setupforcerun
    if (!(Test-Path $setupControlDoNotRun )) {
        if ($PSEdition -ne 'Core' -and ($null -eq (Get-Command pwsh -ErrorAction SilentlyContinue))) {
            Write-Output "PowerShell Core is not available and Setup cannot run. Install it from https://aka.ms/PSWindows, and then start PowerShell again."
        } else {
            if (Test-Elevated) {
                $choices = @(
                    [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run setup")
                    [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run setup at this time")
                    [System.Management.Automation.Host.ChoiceDescription]::new("&Don't ask again", "Don't ask to run setup again")
                )
                if ((Test-Path $setupControlForceRun) -and $PSEdition -eq 'Core') {
                    Remove-Item -Force $setupControlForceRun
                    & "$PSScriptRoot/Setup.ps1"
                } else {
                    $script:runSetup = $Host.UI.PromptForChoice("Run setup?", "Setup has not ran yet, do you want to run it now?", $choices, 1)
                    switch ($runSetup) {
                        0 {
                            if ($PSEdition -ne 'Core') {
                                New-Item -ItemType File "$setupControlForceRun" | Out-Null
                                pwsh -File "$PSScriptRoot/Setup.ps1"
                            } else {
                                & "$PSScriptRoot/Setup.ps1"
                            }
                        }
                        2 {
                            New-Item -ItemType File "$setupControlDoNotRun" | Out-Null
                            if ($IsWindows) { (Get-Item $setupControlDoNotRun).Attributes += 'Hidden' }
                            Write-Output "You will not be asked to run setup again. If you want to run it, run $(Join-Path $PSScriptRoot Setup.ps1), or delete the file '$setupControlDoNotRun' and restart PowerShell."
                        }
                        Default {}
                    }
                }
            } else {
                Write-Warning "Setup has not ran yet. Run this script as administrator in PowerShell Core to run setup."
            }
        }
    }
}

. "$profileDir/SetViMode.ps1" # always set vi mode before loading modules because of keybindings conflict with PSFzf
. "$profileDir/ImportModules.ps1"

if (!(Get-Process ssh-agent -ErrorAction Ignore) -and (Test-Path (Join-Path (Join-Path $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }) .ssh) id_rsa))) {
    Start-SshAgent -Quiet
}
if (Get-Command colortool -ErrorAction Ignore) { colortool --quiet campbell.ini }

$kubeConfigHome = Join-Path $env:HOME '.kube'
if (Test-Path $kubeConfigHome) {
    & {
        $kubeConfig = ''
        $env:KUBECONFIG = Get-ChildItem $kubeConfigHome -File | ForEach-Object {} { $kubeConfig += "$($_.FullName)$([System.IO.Path]::PathSeparator)" } { $kubeConfig }
    }
}
Remove-Variable kubeConfigHome

if ((Get-Command bat -CommandType Application -ErrorAction Ignore) -and (Get-Command less -CommandType Application -ErrorAction Ignore)) {
    $env:BAT_PAGER = "less -RF"
}

if (Get-Module PSReadLine) {
    if ($(Get-PSReadLineOption).PredictionSource -eq 'None') {
        Set-PSReadLineOption -PredictionSource History
    }
}

$env:DOCKER_BUILDKIT = 1

. "$profileDir/Completions.ps1"
. "$profileDir/CreateAliases.ps1"

if ($IsWindows) {
    . "$profileDir/profile.windows.ps1"
    . "$profileDir/CreateAliases.windows.ps1"
}

function Add-Starship {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', "", Scope = 'function', Justification = 'This is how you setup starship')]
    param()
    if (Get-Command starship -ErrorAction Ignore) {
        $env:STARSHIP_CONFIG = Join-Path $profileDir "starship.toml"
        Invoke-Expression (&starship init powershell --print-full-init | Out-String)
    } else {
        Write-Output "Install Starship to get a nice theme. Go to: https://starship.rs/"
    }
}
Add-Starship
Remove-Item -Path Function:\Add-Starship

# cleanup:
Set-StrictMode -Off
Remove-Variable localModulesDirectory
Remove-Variable localAdditionalModulesDirectory
Remove-Variable profileDir
$ErrorActionPreference = 'Continue'
