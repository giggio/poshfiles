Set-StrictMode -Version 3.0

$isWin = [System.Environment]::OSVersion.Platform -eq 'Win32NT'
if ($isWin -and $null -eq $env:HOME -and $null -ne $env:USERPROFILE) {
    $env:HOME = $env:USERPROFILE
}
$script:profileDir = Join-Path $PSScriptRoot Profile
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
. "$profileDir/Functions.ps1"

if ($isWin) {
    . "$profileDir/profile.windows.ps1"
    . "$profileDir/CreateAliases.windows.ps1"
    . "$profileDir/WindowsDefenderExclusions.ps1"
}

if (Get-Command starship -ErrorAction Ignore) {
    $env:STARSHIP_CONFIG = Join-Path $profileDir "starship.toml"
    Invoke-Expression (&starship init powershell)
} else {
    Write-Output "Install Starship to get a nice theme. Go to: https://starship.rs/"
}
