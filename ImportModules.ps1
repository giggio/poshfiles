$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$localModulesDirectory = Join-Path $root Modules

Import-Module "$localModulesDirectory/posh-git/src/posh-git.psd1" # slow
Import-Module "$localModulesDirectory/oh-my-posh/oh-my-posh.psm1" #don't import the psd1, it has an incorrect string in the version field
Import-Module "$localModulesDirectory/PowerShellGuard/PowerShellGuard.psm1" #don't import the psd1, it has an incorrect string in the version field
Import-Module "$localModulesDirectory/DockerCompletion/DockerCompletion/DockerCompletion.psd1"
Import-Module "$localModulesDirectory/posh-alias/Posh-Alias.psd1"
if ($isWin) {
    if (Test-Path "$root/Modules/PSFzf/PSFzf.dll") {
        Import-Module "$localModulesDirectory/PSFzf/PSFzf.psd1" -ArgumentList 'Ctrl+t', 'Ctrl+r' -Force
        if ($env:WT_SESSION) {
            Set-PsFzfOption -TabExpansion -GitKeyBindings
        } else {
            Set-PsFzfOption -TabExpansion
        }
    }
    Import-Module "$localModulesDirectory/git-status-cache-posh-client/GitStatusCachePoshClient.psm1"
    if (!(Test-Path "$localModulesDirectory/git-status-cache-posh-client/bin/GitStatusCache.exe")) { Update-GitStatusCache }
    # Chocolatey profile
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile"
    }
}
