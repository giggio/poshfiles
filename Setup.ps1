#Requires -RunAsAdministrator
#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

$script:setupControl = Join-Path $PSScriptRoot .setupran
function RunSetup {
    $script:setupDir = Join-Path $PSScriptRoot Setup
    $script:profileDir = Join-Path $PSScriptRoot Profile
    & "$setupDir/InstallModules.ps1"
    & "$setupDir/InstallTools.ps1"

    if ($IsWindows) {
        . "$setupDir/WindowsDefenderExclusions.ps1"
        Add-WindowsDefenderExclusions
        . "$setupDir/Configure-Windows.ps1"

        $ssha = Get-Service ssh-agent -ErrorAction SilentlyContinue
        if ($null -ne $ssha) {
            if ($null -ne $env:SSH_AUTH_SOCK) {
                if ($ssha.StartType -eq 'Automatic') {
                    Write-Output "Setting ssh-agent to manual."
                    Set-Service $ssha -StartMode Manual
                }
            } else {
                if ($ssha.StartType -eq 'Manual') {
                    Write-Output "Setting ssh-agent to automatic."
                    Set-Service $ssha -StartMode Automatic
                }
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
    }
    if (!(Test-Path $setupControl)) {
        New-Item -ItemType File "$setupControl" | Out-Null
        if ($IsWindows) { (Get-Item $setupControl).Attributes += 'Hidden' }
    }
}

function CheckSetup {
    if (!(Test-Path $setupControl)) {
        $script:setupControlDoNotRun = Join-Path $PSScriptRoot .setupdonotrun
        $script:setupControlForceRun = Join-Path $PSScriptRoot .setupforcerun
        if (!(Test-Path $setupControlDoNotRun )) {
            if ($PSEdition -ne 'Core' -and ($null -eq (Get-Command pwsh -ErrorAction SilentlyContinue))) {
                Write-Output "PowerShell Core is not available and Setup cannot run. Install it from https://aka.ms/PSWindows, and then start PowerShell again."
            } else {
                if ($IsLinux -or $IsMacOS -or (Test-Elevated)) {
                    if ((Test-Path $setupControlForceRun) -and $PSEdition -eq 'Core') {
                        Remove-Item -Force $setupControlForceRun
                        RunSetup
                    } else {
                        $choices = @(
                            [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run setup (elevated)")
                            [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run setup at this time")
                            [System.Management.Automation.Host.ChoiceDescription]::new("&Don't ask again", "Don't ask to run setup again")
                        )
                        $script:runSetup = $Host.UI.PromptForChoice("Run setup?", "Setup has not ran yet, do you want to run it now?", $choices, 1)
                        switch ($runSetup) {
                            0 {
                                if ($PSEdition -ne 'Core') {
                                    New-Item -ItemType File "$setupControlForceRun" | Out-Null
                                    pwsh -File "$($MyInvocation.MyCommand.Path)"
                                } else {
                                    RunSetup
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
}

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    RunSetup
}
