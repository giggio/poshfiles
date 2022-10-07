#Requires -RunAsAdministrator

$script:setupDir = Join-Path $PSScriptRoot Setup
. "$setupDir/InstallModules.ps1"
. "$setupDir/InstallTools.ps1"

if ($isWin) {

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

