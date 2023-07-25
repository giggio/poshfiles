Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:profileDir = Join-Path $PSScriptRoot Profile
. "$profileDir/Common.ps1"
if ($IsWindows -and $null -eq $env:HOME -and $null -ne $env:USERPROFILE) {
    $env:HOME = $env:USERPROFILE
}
. "$profileDir/Functions.ps1"
Sync-Path

if ($IsWindows) {
    . "$PSScriptRoot/Run-Setup.ps1"
}
. "$profileDir/SetViMode.ps1" # always set vi mode before loading modules because of keybindings conflict with PSFzf
. "$profileDir/ImportModules.ps1"

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
}

. "$profileDir/Prompt.ps1"

# cleanup:
Set-StrictMode -Off
Remove-Variable localModulesDirectory
Remove-Variable localAdditionalModulesDirectory
Remove-Variable profileDir
$ErrorActionPreference = 'Continue'
