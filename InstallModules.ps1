$localModulesDirectory = "$root\Modules"

function ModuleMissing($moduleName) {
    ($env:PSModulePath.Split([System.IO.Path]::PathSeparator) | `
            ForEach-Object { Join-Path $_ $moduleName } | `
            ForEach-Object { Test-Path $_ }).Where( {$_} ).Count -eq 0
}

if (!($env:PSModulePath.Contains($localModulesDirectory))) {
    $env:PSModulePath = "$localModulesDirectory;$env:PSModulePath"
}

if (!(Test-Path "$localModulesDirectory\PowerShellGet")) {
    Save-Module -Name PowerShellGet -Path $localModulesDirectory -Confirm
}

if (ModuleMissing VSSetup) {
    Save-Module VSSetup $localModulesDirectory -Confirm
}

if ((Get-Module PSReadLine).Version.Major -lt 2) {
    if (!(Test-Path "$localModulesDirectory\PSReadLine")) {
        Save-Module PSReadLine $localModulesDirectory -Confirm -AllowPrerelease -Force
    }
    Remove-Module PSReadline
    Import-Module $localModulesDirectory\PSReadLine
}
