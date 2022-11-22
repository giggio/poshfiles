#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

if (!$IsWindows) {
    Write-Warning "This script is only for Windows."
    exit
}

$ErrorActionPreference = 'stop'
$script:profileDir = Join-Path $PSScriptRoot .. Profile
. "$profileDir/Functions.ps1"

if (Test-Elevated) {
    Write-Error "This script must not be run as administrator."
    exit 1
}

& "$PSScriptRoot/Install-PlatformTools.ps1"

function Add-Scoop {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', "", Scope = 'function', Justification = 'This is how you setup scoop')]
    param()
    if (!(Get-Command scoop -ErrorAction Ignore)) {
        if (Test-Path "$env:USERPROFILE\scoop\shims\scoop.ps1") {
            $env:PATH += ";$env:USERPROFILE\scoop\shims\"
        } else {
            Invoke-RestMethod get.scoop.sh | Invoke-Expression
        }
    }
}
Add-Scoop
Remove-Item -Path Function:\Add-Scoop

function Invoke-ScoopSetup {
    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run scoop setup")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run scoop setup")
        [System.Management.Automation.Host.ChoiceDescription]::new("&View", "View scoop apps")
    )
    $script:runScoop = $Host.UI.PromptForChoice("Run scoop setup?", "Review the scoop file before you import it. Do you want to run it now?", $choices, 1)
    switch ($runScoop) {
        0 {
            #run
            scoop import $PSScriptRoot\scoopfile.json
        }
        2 {
            #view
            Write-Host "Scoop apps:"
                (Get-Content $PSScriptRoot/scoopfile.json | ConvertFrom-Json).Apps.Name | Format-Table | Out-String | ForEach-Object { Write-Host $_ }
            Invoke-ScoopSetup
        }
        Default {}
    }
}
Invoke-ScoopSetup
Remove-Item -Path Function:\Invoke-ScoopSetup
