Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:profileDir = Join-Path $PSScriptRoot Profile
. "$profileDir/Common.ps1"
if ($IsWindows -and $null -eq $env:HOME -and $null -ne $env:USERPROFILE) {
    $env:HOME = $env:USERPROFILE
}
. "$profileDir/Functions.ps1"

$script:setupControl = Join-Path $PSScriptRoot .setupran
if (!(Test-Path $setupControl)) {
    $script:setupControlDoNotRun = Join-Path $PSScriptRoot .setupdonotrun
    if (!(Test-Path $setupControlDoNotRun )) {
        if (Test-Elevated) {
            $choices = @(
                [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run setup")
                [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run setup at this time")
                [System.Management.Automation.Host.ChoiceDescription]::new("&Don't ask again", "Don't ask to run setup again")
            )
            $script:runSetup = $Host.UI.PromptForChoice("Run setup?", "Setup has not ran yet, do you want to run it now?", $choices, 1)
            switch ($runSetup) {
                0 {
                    . "$PSScriptRoot/Setup.ps1"
                }
                2 {
                    New-Item -ItemType File "$setupControlDoNotRun" | Out-Null
                    if ($IsWindows) { (Get-Item $setupControlDoNotRun).Attributes += 'Hidden' }
                    Write-Host "You will not be asked to run setup again. If you want to run it, run $(Join-Path $PSScriptRoot Setup.ps1), or delete the file '$setupControlDoNotRun' and restart PowerShell."
                }
                Default {}
            }
        } else {
            Write-Warning "Setup has not ran yet. Run this script as administrator to run setup."
        }
    }
}

. "$profileDir/SetViMode.ps1"
. "$profileDir/ImportModules.ps1"

if (!(Get-Process ssh-agent -ErrorAction Ignore) -and (Test-Path (Join-Path (Join-Path $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }) .ssh) id_rsa))) {
    Start-SshAgent -Quiet
}
if (Get-Command colortool -ErrorAction Ignore) { colortool --quiet campbell.ini }

$kubeConfigHome = Join-Path $env:HOME '.kube'
if (Test-Path $kubeConfigHome) {
    $env:KUBECONFIG = Get-ChildItem $kubeConfigHome -File | ForEach-Object { $kubeConfig = '' } { $kubeConfig += "$($_.FullName)$([System.IO.Path]::PathSeparator)" } { $kubeConfig }
    Remove-Variable kubeConfig
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

if (Get-Command starship -ErrorAction Ignore) {
    $env:STARSHIP_CONFIG = Join-Path $profileDir "starship.toml"
    Invoke-Expression (&starship init powershell)
} else {
    Write-Output "Install Starship to get a nice theme. Go to: https://starship.rs/"
}
