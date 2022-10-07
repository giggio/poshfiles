$localModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Modules)
if (!($env:PSAdditionalModulePath)) {
    $env:PSAdditionalModulePath = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) AdditionalModules)
}
if (!(Test-Path $env:PSAdditionalModulePath)) {
    New-Item -Type Directory $env:PSAdditionalModulePath -Force | Out-Null
}

function ModuleMissing($moduleName) {
    ($env:PSModulePath.Split([System.IO.Path]::PathSeparator, [System.StringSplitOptions]::RemoveEmptyEntries) | `
        ForEach-Object { Join-Path $_ $moduleName } | `
        ForEach-Object { Test-Path $_ }).Where( { $_ } ).Count -eq 0
}

if (!(Test-Path (Join-Path $localModulesDirectory PowerShellGet))) {
    Save-Module -Name PowerShellGet -Path $localModulesDirectory -Confirm:$false
}

if (!(Test-Path (Join-Path $localModulesDirectory psake))) {
    Save-Module -Name psake -Path $localModulesDirectory -Confirm:$false
}
$psakeTabExpansionFile = Join-Path (Join-Path $localModulesDirectory psake) PsakeTabExpansion.ps1
if (!(Test-Path $psakeTabExpansionFile)) {
    Invoke-WebRequest -Uri https://github.com/psake/psake/raw/master/tabexpansion/PsakeTabExpansion.ps1 -OutFile $psakeTabExpansionFile
}

if (ModuleMissing VSSetup) {
    Save-Module VSSetup $localModulesDirectory -Confirm:$false
}

if (ModuleMissing Terminal-Icons) {
    Save-Module Terminal-Icons $localModulesDirectory -Confirm:$false
}

if ((ModuleMissing Pester) -or (((Get-Module Pester -ListAvailable).Version.Major | Measure-Object -Maximum).Maximum -lt 5)) {
    Save-Module Pester $localModulesDirectory -Confirm:$false
}

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    if (ModuleMissing AzureADPreview) {
        Save-Module AzureADPreview $localModulesDirectory -Confirm:$false
    }
    if (ModuleMissing ExchangeOnlineManagement) {
        Save-Module ExchangeOnlineManagement $localModulesDirectory -Confirm:$false
    }
}

if (ModuleMissing PSScriptAnalyzer) {
    Save-Module PSScriptAnalyzer $localModulesDirectory -Confirm:$false
}
