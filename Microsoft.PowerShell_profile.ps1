$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$isWin = [System.Environment]::OSVersion.Platform -eq 'Win32NT'
if ($isWin -and $null -eq $env:HOME -and $null -ne $env:USERPROFILE) {
    $env:HOME = $env:USERPROFILE
}
. "$root/InstallModules.ps1"
. "$root/SetViMode.ps1"

if ($isWin -and (Test-Path "$env:ProgramFiles\Git\usr\bin") -and ($env:path.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0)) {
    # enable ssh-agent from posh-git
    $env:PATH = "$env:PATH;$env:ProgramFiles\Git\usr\bin"
}

. "$root/InstallTools.ps1"
. "$root/ImportModules.ps1"

if (!(Get-Process ssh-agent -ErrorAction Ignore)) {
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

. "$root/Completions.ps1"
. "$root/CreateAliases.ps1"
. "$root/Functions.ps1"

if ($isWin) {
    . "$root/profile.windows.ps1"
    . "$root/CreateAliases.windows.ps1"
}

if (Get-Command starship -ErrorAction Ignore) {
    Invoke-Expression (&starship init powershell)
} else {
    Write-Output "Install Starship to get a nice theme. Go to: https://starship.rs/"
}

$root = $null
