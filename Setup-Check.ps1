#Requires -PSEdition Core
#Requires -Version 7.2

Set-StrictMode -Version 3.0

$script:setupControl = Join-Path $PSScriptRoot .setupran

function CheckSetup([switch]$BypassCheck = $false) {
    if (!(Test-Path $setupControl) -or $BypassCheck) {
        $script:setupControlDoNotRun = Join-Path $PSScriptRoot .setupdonotrun
        if (!(Test-Path $setupControlDoNotRun)) {
            if ($IsLinux -or $IsMacOS -or (Test-Elevated) -or (Get-Command sudo -ErrorAction Ignore)) {
                $choices = @(
                    [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run setup (elevated)")
                    [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run setup at this time")
                    [System.Management.Automation.Host.ChoiceDescription]::new("&Don't ask again", "Don't ask to run setup again")
                )
                $script:runSetup = $Host.UI.PromptForChoice("Run elevated setup?", "Setup has not ran yet, do you want to run it now? If you are not in an elevated prompt you may be prompted by UAC to continue.", $choices, 1)
                switch ($runSetup) {
                    0 {
                        if (Test-Elevated) {
                            . "$PSScriptRoot/Setup.ps1" -RunNow
                        } else {
                            sudo pwsh -NoProfile -File "$PSScriptRoot/Setup.ps1" -RunNow
                        }
                    }
                    2 {
                        New-Item -ItemType File "$setupControlDoNotRun" | Out-Null
                        if ($IsWindows) { (Get-Item $setupControlDoNotRun).Attributes += 'Hidden' }
                        Write-Output "You will not be asked to run setup again. If you want to run it, run $(Join-Path $PSScriptRoot Setup-Check.ps1), or delete the file '$setupControlDoNotRun' and restart PowerShell."
                    }
                    Default {}
                }
            } else {
                Write-Warning "Setup has not ran yet. Run this script as administrator in PowerShell Core to run setup."
            }
        }
    }
}
$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    if ((Test-Elevated) -or (Get-Command sudo -ErrorAction Ignore)) {
        CheckSetup -BypassCheck
    }
}
