#Requires -RunAsAdministrator
#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

$ErrorActionPreference = 'stop'
$script:rootDir = Resolve-Path (Join-Path $PSScriptRoot ..)
$script:localModulesDirectory = Join-Path $rootDir Modules
$script:profileDir = Join-Path $rootDir Profile
. "$profileDir/Functions.ps1"

if (Get-Command fzf -ErrorAction Ignore) {
    function CreateFzfPsm1() {
        if (!(Test-Path "$localModulesDirectory/PSFzf/PSFzf.psm1")) {
            Write-Output "Creating $localModulesDirectory/PSFzf/PSFzf.psm1..."
            . "$localModulesDirectory/PSFzf/helpers/Join-ModuleFiles.ps1"
        }
    }
    if (!(Test-Path "$localModulesDirectory/PSFzf/PSFzf.dll")) {
        if (Get-Command dotnet -ErrorAction Ignore) {
            $fzfTempDir = Join-Path "$([System.IO.Path]::GetTempPath())" fzf
            New-Item -Type Directory $fzfTempDir -Force | Out-Null
            dotnet build --nologo --verbosity quiet --configuration Release --output $fzfTempDir "$localModulesDirectory/PSFzf/PSFzf-Binary/PSFzf-Binary.csproj"
            Copy-Item $fzfTempDir/PSFzf.dll "$localModulesDirectory/PSFzf/"
            CreateFzfPsm1
            Remove-Item -Force -Recurse $fzfTempDir
        }
    }
    CreateFzfPsm1
}

function Invoke-WingetSetup {
    function InstallWinget([System.IO.FileInfo]$file) {
        winget import --import-file $file --accept-source-agreements --accept-package-agreements
        # not all apps are installed (winget bug), so we'll just install manually parsing the file
        winget export -o $env:temp/winget-installed.json
        $installed = (Get-Content $env:temp/winget-installed.json | ConvertFrom-Json).Sources.Packages.PackageIdentifier
        [array]$toInstall = (Get-Content $file | ConvertFrom-Json).Sources.Packages.PackageIdentifier `
        | Where-Object { ! $installed.Contains($_) }
        if ($null -ne $toInstall) {
            Write-Host "Going to install $($toInstall.Count) apps: $($toInstall -join ', ')"
            $toInstall | ForEach-Object { winget install --accept-package-agreements --id $_ }
        } else {
            Write-Host "All apps are already installed."
        }
        Remove-Item $env:temp/winget-installed.json
    }
    function ViewWingetApps([System.IO.FileInfo]$file) {
        Write-Host "Winget apps:"
        (Get-Content $file | ConvertFrom-Json).Sources.Packages.PackageIdentifier | Format-Table | Out-String | ForEach-Object { Write-Host $_ }
    }

    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run winget setup, agreeing with source and package agreements")
        [System.Management.Automation.Host.ChoiceDescription]::new("Yes (&essential apps only)", "Run winget setup, agreeing with source and package agreements, but install only essential apps.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run winget setup")
        [System.Management.Automation.Host.ChoiceDescription]::new("&View", "View winget apps")
        [System.Management.Automation.Host.ChoiceDescription]::new("Vie&w essential apps", "View essential winget apps")
    )
    $script:runWinget = $Host.UI.PromptForChoice("Run winget setup?", "Review the winget file before you import it. Do you want to run it now?", $choices, 2)
    switch ($runWinget) {
        0 {
            #install
            InstallWinget "$PSScriptRoot\winget.json"
        }
        1 {
            #install essential apps
            InstallWinget "$PSScriptRoot\winget-essentials.json"
        }
        3 {
            #view
            ViewWingetApps "$PSScriptRoot\winget.json"
            Invoke-WingetSetup
        }
        3 {
            #view essential apps
            ViewWingetApps "$PSScriptRoot\winget-essentials.json"
            Invoke-WingetSetup
        }
        Default {}
    }
}
Invoke-WingetSetup
Remove-Item -Path Function:\Invoke-WingetSetup

function Invoke-ChocoSetup {
    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run choco setup, agreeing with source and package agreements")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run choco setup")
        [System.Management.Automation.Host.ChoiceDescription]::new("&View", "View choco apps")
    )
    $script:runWinget = $Host.UI.PromptForChoice("Run choco setup?", "Review the Chocolatey file before you import it. Do you want to run it now?", $choices, 1)
    switch ($runWinget) {
        0 {
            #install
            $choco = 'choco'
            if (Get-Command choco -ErrorAction Ignore) {
                $choco = "$env:ProgramData\chocolatey\bin\choco.exe"
                if (!(Test-Path $choco)) {
                    winget install --id Chocolatey.Chocolatey --source winget --accept-package-agreements --accept-source-agreements
                }
                if (!(Test-Path $choco)) {
                    Write-Warning "Chocolatey is not installed and trying to install it did not work, choco packages will not be installed."
                    return
                }
            }
            & $choco install "$PSScriptRoot\choco-export.config" --yes
        }
        2 {
            #view
            [xml]$chocoPackages = Get-Content "$PSScriptRoot\choco-export.config"
            Write-Host "Choco apps:"
            $chocoPackages.packages.package.id | ForEach-Object { Write-Host $_ }
            Invoke-ChocoSetup
        }
        Default {}
    }
}
Invoke-ChocoSetup
Remove-Item -Path Function:\Invoke-ChocoSetup

powershell.exe -NoProfile -File $PSScriptRoot\InstallTools-Windows-Powershell.ps1
Test-Error
