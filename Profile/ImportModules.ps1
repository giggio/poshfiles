$script:localModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Modules)
$script:localAdditionalModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) AdditionalModules)

$script:setupScriptPath = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Setup.ps1)
if (!($env:PSModulePath.Contains($localModulesDirectory))) {
    Write-Warning "PSModulePath does not contain local module PATH '$localModulesDirectory'. Adding it now, but modules may not work as expected. Run the Setup Script ($setupScriptPath) so your PSModulePath registry and/or config file is set correctly."
    $env:PSModulePath = "$localModulesDirectory$([System.IO.Path]::PathSeparator)$env:PSModulePath"
}

if (!($env:PSModulePath.Contains($localAdditionalModulesDirectory))) {
    Write-Warning "PSModulePath does not contain local additional module PATH '$localAdditionalModulesDirectory'. Adding it now, but modules may not work as expected. Run the Setup Script ($setupScriptPath) so your PSModulePath registry and/or config file is set correctly."
    $env:PSModulePath = "$localAdditionalModulesDirectory$([System.IO.Path]::PathSeparator)$env:PSModulePath"
}

if (!$env:PSModulePath.StartsWith("$localAdditionalModulesDirectory$([System.IO.Path]::PathSeparator)$localModulesDirectory")) {
    Write-Warning "PSModulePath does not have the module directories in correct order and PowerShell modules may have incorrect versions. Run the Setup Script ($setupScriptPath) so your PSModulePath registry and/or config file is set correctly."
}

function Import-ModuleIfExists($moduleNameOrPath) {
    if (Test-Path (Join-Path $localModulesDirectory $moduleNameOrPath)) {
        Import-Module (Join-Path $localModulesDirectory $moduleNameOrPath)
    } elseif (Test-Path $moduleNameOrPath) {
        Import-Module $moduleNameOrPath
    }
}

Import-ModuleIfExists posh-git/src/posh-git.psd1
Import-ModuleIfExists "PowerShellGuard/PowerShellGuard.psm1" #don't import the psd1, it has an incorrect string in the version field
Import-ModuleIfExists "DockerCompletion/DockerCompletion/DockerCompletion.psd1"
Import-ModuleIfExists "posh-alias/Posh-Alias.psd1"
Import-ModuleIfExists Terminal-Icons

if ($IsWindows) {
    if (Test-Path "$localModulesDirectory/PSFzf/PSFzf.dll") {
        Import-Module "$localModulesDirectory/PSFzf/PSFzf.psd1" -ArgumentList 'Ctrl+t', 'Ctrl+r' -Force
        if ($env:WT_SESSION) {
            Set-PsFzfOption -TabExpansion -GitKeyBindings
        } else {
            Set-PsFzfOption -TabExpansion
        }
    }
    # Chocolatey profile
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile"
    }
}
