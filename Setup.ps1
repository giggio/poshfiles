#Requires -RunAsAdministrator
Set-StrictMode -Version 3.0

Push-Location $PSScriptRoot | Out-Null
git submodule update --init --recursive
Pop-Location

$script:setupDir = Join-Path $PSScriptRoot Setup
. "$setupDir/InstallModules.ps1"
. "$setupDir/InstallTools.ps1"

if ($isWin) {
    . "$setupDir/WindowsDefenderExclusions.ps1"
    Add-WindowsDefenderExclusions -Quiet

    $ssha = Get-Service ssh-agent -ErrorAction SilentlyContinue
    if ($null -ne $ssha) {
        if ($null -ne $env:SSH_AUTH_SOCK) {
            if ($ssha.StartType -eq 'Automatic') {
                Write-Host "Setting ssh-agent to manual."
                Set-Service $ssha -StartMode Manual
            }
        } else {
            if ($ssha.StartType -eq 'Manual') {
                Write-Host "Setting ssh-agent to automatic."
                Set-Service $ssha -StartMode Automatic
            }
        }
    }

    if (Test-Path "$env:ProgramFiles\Git\usr\bin") {
        # git tools
        if ($env:path.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0) {
            Write-Host "Setting local PATH to use Git tools."
            $env:PATH = "$env:PATH;$env:ProgramFiles\Git\usr\bin"
        }
        $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
        if ($machinePath.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0) {
            Write-Host "Setting machine PATH to use Git tools."
            [Environment]::SetEnvironmentVariable('PATH', "$machinePath;$env:ProgramFiles\Git\usr\bin", 'Machine')
        }
    }
}
$script:setupControl = Join-Path $PSScriptRoot .setupran
if (!(Test-Path $setupControl)) {
    New-Item -ItemType File "$setupControl" | Out-Null
    if ($isWin) { (Get-Item $setupControl).Attributes += 'Hidden' }
}
