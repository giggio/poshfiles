$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$isWin = [System.Environment]::OSVersion.Platform -eq 'Win32NT'
if ($isWin -and $null -eq $env:HOME -and $null -ne $env:USERPROFILE) {
    $env:HOME = $env:USERPROFILE
}

. "$root/InstallModules.ps1"

if ($isWin -and (Test-Path "$env:ProgramFiles\Git\usr\bin") -and ($env:path.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0)) {
    # enable ssh-agent from posh-git
    $env:PATH = "$env:PATH;$env:ProgramFiles\Git\usr\bin"
}
Import-Module "$root/Modules/posh-git/src/posh-git.psd1"
Import-Module "$root/Modules/oh-my-posh/oh-my-posh.psm1" #don't import the psd1, it has an incorrect string in the version field
Import-Module "$root/Modules/PowerShellGuard/PowerShellGuard.psm1" #don't import the psd1, it has an incorrect string in the version field
Import-Module "$root/Modules/psake/src/psake.psd1"
Import-Module "$root/Modules/DockerCompletion/DockerCompletion/DockerCompletion.psd1"
if ($isWin) { Import-Module $root\Modules\z\z.psm1 }

if (!(Get-Process ssh-agent -ErrorAction Ignore)) {
    Start-SshAgent -Quiet
}
$ThemeSettings.MyThemesLocation = Join-Path $root PoshThemes
Set-Theme Mesh
if (Get-Command colortool -ErrorAction Ignore) { colortool --quiet campbell.ini }

if (Get-Command vim -ErrorAction Ignore) {
    Set-PSReadlineOption -EditMode Vi
    Set-PSReadlineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
    Set-PSReadlineKeyHandler -Key Ctrl+Shift+r -Function ForwardSearchHistory
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadlineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
    if (!($env:VISUAL)) {
        $env:VISUAL = "vim"
    }
    if (!($env:GIT_EDITOR)) {
        $vimPath = (Get-Command vim).Path
        $env:GIT_EDITOR = "'$vimPath'"
    }
}

$kubeConfigHome = Join-Path $env:HOME '.kube'
if (Test-Path $kubeConfigHome) {
    $env:KUBECONFIG = Get-ChildItem $kubeConfigHome -File | ForEach-Object { $kubeConfig = '' } { $kubeConfig += "$($_.FullName)$([System.IO.Path]::PathSeparator)" } { $kubeConfig }
    Remove-Variable kubeConfig
}
Remove-Variable kubeConfigHome

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        [array]$vss = . $vswhere -version 16 -property installationpath
        if ($vss.Count -ne 0) {
            $vsPath = $vss[0]
            Import-Module "$vsPath\Common7\Tools\vsdevshell\Microsoft.VisualStudio.DevShell.dll"
            Enter-VsDevShell -VsInstallPath $vsPath > $null
        }
    }
    elseif (Get-Module VSSetup) {
        [array]$vss = Get-VSSetupInstance | Where-Object { $_.InstallationVersion.Major -ge 17 } | Select-Object -Property InstallationPath -First 1
        if ($vss.Count -ne 0) {
            $vsPath = $vss[0].InstallationPath
            Import-Module "$vsPath\Common7\Tools\vsdevshell\Microsoft.VisualStudio.DevShell.dll"
            Enter-VsDevShell -VsInstallPath $vsPath > $null
        }
    }
}

. "$root/InstallTools.ps1"
. "$root/Completions.ps1"
. "$root/CreateAliases.ps1"
. "$root/Functions.ps1"

$root = $null
