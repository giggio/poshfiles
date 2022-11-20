Set-StrictMode -Version 3.0

$script:setupControl = Join-Path $PSScriptRoot .setupran

function CheckSetup {
    if (!(Test-Path $setupControl)) {
        $script:setupControlDoNotRun = Join-Path $PSScriptRoot .setupdonotrun
        if (!(Test-Path $setupControlDoNotRun)) {
            if ($PSEdition -ne 'Core' -and ($null -eq (Get-Command pwsh -ErrorAction SilentlyContinue))) {
                Write-Output "PowerShell Core is not available and Setup cannot run. Install it from https://aka.ms/PSWindows, and then start PowerShell again."
            } else {
                if ($IsLinux -or $IsMacOS -or (Test-Elevated) -or (Get-Command sudo -ErrorAction Ignore)) {
                    $choices = @(
                        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run setup (elevated)")
                        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run setup at this time")
                        [System.Management.Automation.Host.ChoiceDescription]::new("&Don't ask again", "Don't ask to run setup again")
                    )
                    $script:runSetup = $Host.UI.PromptForChoice("Run setup?", "Setup has not ran yet, do you want to run it now?", $choices, 1)
                    switch ($runSetup) {
                        0 {
                            if (Test-Elevated) {
                                if ($PSEdition -ne 'Core') {
                                    pwsh -NoProfile -File "$PSScriptRoot/Setup.ps1" -RunNow
                                } else {
                                    . "$PSScriptRoot/Setup.ps1" -RunNow
                                }
                            } else {
                                sudo pwsh -NoProfile -File "$PSScriptRoot/Setup.ps1" -RunNow
                            }
                        }
                        2 {
                            New-Item -ItemType File "$setupControlDoNotRun" | Out-Null
                            if ($IsWindows) { (Get-Item $setupControlDoNotRun).Attributes += 'Hidden' }
                            Write-Output "You will not be asked to run setup again. If you want to run it, run $(Join-Path $PSScriptRoot Setup.ps1), or delete the file '$setupControlDoNotRun' and restart PowerShell."
                        }
                        Default {}
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
    if (Test-Elevated -or (Get-Command sudo -ErrorAction Ignore)) {
        CheckSetup
    }
}
