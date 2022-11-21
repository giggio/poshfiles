Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:profileDir = Join-Path $PSScriptRoot Profile
. "$profileDir/Common.ps1"
if ($IsWindows -and $null -eq $env:HOME -and $null -ne $env:USERPROFILE) {
    $env:HOME = $env:USERPROFILE
}
. "$profileDir/Functions.ps1"

if (Test-Elevated) {
    if ($PSEdition -eq 'Core') {
        . "$PSScriptRoot/Setup-Check.ps1"
        CheckSetup
    } else {
        . "$PSScriptRoot/Setup/Setup-Bootstrap.ps1"
        Sync-Path
        if ($null -eq (Get-Command pwsh -ErrorAction SilentlyContinue)) {
            Write-Warning "PowerShell Core is not available and Setup cannot run. Install it from https://aka.ms/PSWindows, and then start PowerShell again."
        } else {
            pwsh -File "$PSScriptRoot/Setup-Check.ps1"
        }
    }
} else {
    if ($PSEdition -eq 'Core') {
        . "$PSScriptRoot/Setup-NonElevated.ps1"
        CheckSetupNonElevated
        . "$PSScriptRoot/Setup-Check.ps1"
        CheckSetup
    } else {
        . "$PSScriptRoot/Setup/Setup-Bootstrap.ps1"
        Sync-Path
        if ($null -eq (Get-Command pwsh -ErrorAction SilentlyContinue)) {
            Write-Warning "PowerShell Core is not available and Setup cannot run. Install it from https://aka.ms/PSWindows, and then start PowerShell again."
        } else {
            pwsh -File "$PSScriptRoot/Setup-NonElevated.ps1"
            pwsh -File "$PSScriptRoot/Setup-Check.ps1"
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

if ((Get-Module PSReadLine) -and ([bool]($(Get-PSReadLineOption).PSobject.Properties.name -match "PredictionSource"))) {
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
        if ($IsWindows) {
            Write-Output "Run $PSScriptRoot\Setup-NonElevated.ps1 and it will be installed with Scoop."
        }
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
