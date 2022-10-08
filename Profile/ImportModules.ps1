$script:localModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Modules)

if (!($env:PSModulePath.Contains($localModulesDirectory))) {
    $env:PSModulePath = "$localModulesDirectory$([System.IO.Path]::PathSeparator)$env:PSModulePath"
}

if (!($env:PSAdditionalModulePath)) {
    $env:PSAdditionalModulePath = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) AdditionalModules)
}
if (!($env:PSModulePath.Contains($env:PSAdditionalModulePath))) {
    $env:PSModulePath = "$env:PSModulePath$([System.IO.Path]::PathSeparator)$env:PSAdditionalModulePath"
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
