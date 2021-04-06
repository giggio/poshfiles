$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$localModulesDirectory = Join-Path $root Modules

function ModuleMissing($moduleName) {
    ($env:PSModulePath.Split([System.IO.Path]::PathSeparator) | `
            ForEach-Object { Join-Path $_ $moduleName } | `
            ForEach-Object { Test-Path $_ }).Where( { $_ } ).Count -eq 0
}

if (!($env:PSModulePath.Contains($localModulesDirectory))) {
    $env:PSModulePath = "$localModulesDirectory$([System.IO.Path]::PathSeparator)$env:PSModulePath"
}

if ($env:PSAdditionalModulePath -and !($env:PSModulePath.Contains($env:PSAdditionalModulePath))) {
    $env:PSModulePath = "$env:PSModulePath$([System.IO.Path]::PathSeparator)$env:PSAdditionalModulePath"
}

if (!(Test-Path (Join-Path $localModulesDirectory PowerShellGet))) {
    Save-Module -Name PowerShellGet -Path $localModulesDirectory -Confirm
}

if (!(Test-Path (Join-Path $localModulesDirectory psake))) {
    Save-Module -Name psake -Path $localModulesDirectory -Confirm
}
$psakeTabExpansionFile = Join-Path (Join-Path $localModulesDirectory psake) PsakeTabExpansion.ps1
if (!(Test-Path $psakeTabExpansionFile)) {
    Invoke-WebRequest -Uri https://github.com/psake/psake/raw/master/tabexpansion/PsakeTabExpansion.ps1 -OutFile $psakeTabExpansionFile
}

if (ModuleMissing VSSetup) {
    Save-Module VSSetup $localModulesDirectory -Confirm
}

if (ModuleMissing Terminal-Icons) {
    Save-Module Terminal-Icons $localModulesDirectory -Confirm
}
