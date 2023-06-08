#Requires -PSEdition Desktop

Set-StrictMode -Version 3
$script:localModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Modules)

function ModuleMissing([Parameter(Mandatory = $true)][string]$moduleName, [System.Version]$minimumVersion) {
    if ($null -eq $minimumVersion) {
        $modules = [array]($env:PSModulePath.Split([System.IO.Path]::PathSeparator, [System.StringSplitOptions]::RemoveEmptyEntries) | `
                ForEach-Object { Join-Path $_ $moduleName } | `
                Where-Object { Test-Path $_ }
        )
        ($null -eq $modules) -or ($modules.Count -eq 0)
    } else {
        $modules = [array]($env:PSModulePath.Split([System.IO.Path]::PathSeparator, [System.StringSplitOptions]::RemoveEmptyEntries) | `
                ForEach-Object { Join-Path $_ $moduleName } | `
                Where-Object { Test-Path $_ } | `
                Where-Object { (Get-Module -ListAvailable $_).Version -ge $minimumVersion } `
        )
        ($null -eq $modules) -or ($modules.Count -eq 0)
    }
}

if (ModuleMissing AzureADPreview) {
    Save-Module AzureADPreview $localModulesDirectory -Confirm:$false
}
if (ModuleMissing ExchangeOnlineManagement) {
    Save-Module ExchangeOnlineManagement $localModulesDirectory -Confirm:$false
}
if (ModuleMissing Microsoft.WinGet.Client) {
    Save-Module Microsoft.WinGet.Client $localModulesDirectory -Confirm:$false
}

