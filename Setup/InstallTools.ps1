#Requires -RunAsAdministrator
#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

$ErrorActionPreference = 'stop'
$script:localModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Modules)
$bin = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) bin)
$env:PATH += $([System.IO.Path]::PathSeparator) + $bin
if (!(Test-Path $bin/tflint*)) {
    $os = ''
    if ($IsWindows) {
        $os = 'windows'
    } elseif ($IsLinux) {
        $os = 'linux'
        return # let's not support Linux yet, it blows up
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tmpFile = (New-TemporaryFile).FullName
    Invoke-WebRequest "https://github.com/wata727/tflint/releases/download/v0.7.0/tflint_$($os)_amd64.zip" -OutFile $tmpFile
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpFile, $bin)
    Remove-Item $tmpFile
}

if ($IsWindows) {
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
    function Add-Scoop {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', "", Scope = 'function', Justification = 'This is how you setup scoop')]
        param()
        if (!(Get-Command scoop -ErrorAction Ignore)) {
            Invoke-RestMethod get.scoop.sh | Invoke-Expression
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
                (Get-Content $PSScriptRoot\scoopfile.json | ConvertFrom-Json).Apps.Name | Format-Table | Out-String | ForEach-Object { Write-Host $_ }
                Invoke-ScoopSetup
            }
            Default {}
        }
    }
    Invoke-ScoopSetup
    Remove-Item -Path Function:\Invoke-ScoopSetup

    function Invoke-WingetSetup {
        $choices = @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Run winget setup, agreeing with source and packcage agreements")
            [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not run winget setup")
            [System.Management.Automation.Host.ChoiceDescription]::new("&View", "View winget apps")
        )
        $script:runWinget = $Host.UI.PromptForChoice("Run winget setup?", "Review the winget file before you import it. Do you want to run it now?", $choices, 1)
        switch ($runWinget) {
            0 {
                #run
                winget import --import-file $PSScriptRoot\winget.json --accept-source-agreements --accept-package-agreements
            }
            2 {
                #view
                Write-Host "Winget apps:"
                (Get-Content $PSScriptRoot\winget.json | ConvertFrom-Json).Sources.Packages.PackageIdentifier | Format-Table | Out-String | ForEach-Object { Write-Host $_ }
                Invoke-WingetSetup
            }
            Default {}
        }
    }
    Invoke-WingetSetup
    Remove-Item -Path Function:\Invoke-WingetSetup
}
