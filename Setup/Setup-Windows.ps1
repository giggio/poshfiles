#Requires -RunAsAdministrator

if (!$IsWindows) {
    Write-Error "This script is only for Windows"
    exit 1
}

$script:setupDir = $PSScriptRoot
Sync-Path
powershell.exe -ExecutionPolicy RemoteSigned  -File "$setupDir/Setup-WindowsPowerShell.ps1"

. "$setupDir/WindowsDefenderExclusions.ps1"
Add-WindowsDefenderExclusions
. "$setupDir/Configure-Windows.ps1"

& "$setupDir/wsl-ssh-pageant-installer/check-install.ps1"
if (!$?) {
    & "$setupDir/wsl-ssh-pageant-installer/install.ps1"
    & "$setupDir/wsl-ssh-pageant-installer/start.ps1"
    $env:SSH_AUTH_SOCK = '\\.\pipe\ssh-pageant'
}

$ssha = Get-Service ssh-agent -ErrorAction SilentlyContinue
if ($null -ne $ssha) {
    # set ssh-agent to start manually, as we're using wsl-ssh-pageant
    if ($ssha.StartType -ne 'Manual') {
        Write-Output "Setting ssh-agent to manual."
        Set-Service $ssha -StartMode Manual
    }
}

if (Test-Path "$env:ProgramFiles\Git\usr\bin") {
    # git tools
    if ($env:path.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0) {
        Write-Output "Setting local PATH to use Git tools."
        $env:PATH = "$env:PATH;$env:ProgramFiles\Git\usr\bin"
    }
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    if ($machinePath.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0) {
        Write-Output "Setting machine PATH to use Git tools."
        [Environment]::SetEnvironmentVariable('PATH', "$machinePath;$env:ProgramFiles\Git\usr\bin", 'Machine')
    }
}
