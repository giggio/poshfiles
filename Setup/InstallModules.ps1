Set-StrictMode -Version 3
$script:localModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Modules)
$script:localAdditionalModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) AdditionalModules)

function FixPSModulePath($path, $messageSuffix) {
    if ($null -eq $path) { $path = '' }
    if (!($path.Contains($localModulesDirectory))) {
        if ($null -ne $messageSuffix) {
            Write-Host "Adding modules directory '$localModulesDirectory' to PSModulePath for $messageSuffix."
        }
        $path = "$localModulesDirectory$([System.IO.Path]::PathSeparator)$path"
    }
    if (!($path.Contains($localAdditionalModulesDirectory))) {
        if ($null -ne $messageSuffix) {
            Write-Host "Adding modules directory '$localAdditionalModulesDirectory' to PSModulePath for $messageSuffix."
        }
        $path = "$localAdditionalModulesDirectory$([System.IO.Path]::PathSeparator)$path"
    }
    if ($path.IndexOf($localModulesDirectory) -lt ($path.IndexOf($localAdditionalModulesDirectory))) {
        if ($null -ne $messageSuffix) {
            Write-Host "Fixing the order of PSModulePath for $messageSuffix."
        }
        $path = $path.Replace("$localModulesDirectory$([System.IO.Path]::PathSeparator)", "")
        $path = $path.Replace("$localAdditionalModulesDirectory", "")
        $path = $path.Replace("$([System.IO.Path]::PathSeparator)$([System.IO.Path]::PathSeparator)", [System.IO.Path]::PathSeparator)
        if ($path.StartsWith($([System.IO.Path]::PathSeparator))) {
            $path = $path.Substring(1)
        }
        $path = "$localAdditionalModulesDirectory$([System.IO.Path]::PathSeparator)$localModulesDirectory$([System.IO.Path]::PathSeparator)$path"
    }
    return $path
}
function FixJsonConfigFile {
    # this is for PowerShell Core which is be done via config file
    # see: help about_powershell_config
    # https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_powershell_config
    $pwshUserDir = Split-Path $PROFILE.CurrentUserCurrentHost
    if (!(Test-Path $pwshUserDir)) { New-Item -ItemType Directory -Path $pwshUserDir }
    $pwshConfigFile = Join-Path $pwshUserDir powershell.config.json
    if (!(Test-Path $pwshConfigFile)) { Set-Content $pwshConfigFile -Value '{}' }
    $pwshConfig = Get-Content -Raw $pwshConfigFile | ConvertFrom-Json -AsHashtable
    $oldPsModulePathForConfigFile = $pwshConfig['PSModulePath']
    $newPSModulePathForConfigFile = FixPSModulePath $oldPsModulePathForConfigFile "config file '$pwshConfigFile'"
    if ($oldPsModulePathForConfigFile -ne $newPSModulePathForConfigFile) {
        Write-Host "Setting PSModulePath in config file '$pwshConfigFile'."
        $pwshConfig.PSModulePath = $newPSModulePathForConfigFile
        $pwshConfigText = ConvertTo-Json $pwshConfig
        Set-Content $pwshConfigFile $pwshConfigText
    }
}
if ($IsWindows) {
    # this is for Windows PowerShell, see PowerShell Core bellow
    # also see: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_psmodulepath#powershell-psmodulepath-construction
    $oldUserPSModulePathForRegistry = [Environment]::GetEnvironmentVariable('PSModulePath', 'User')
    $newUserPSModulePathForRegistry = FixPSModulePath $oldUserPSModulePathForRegistry  "USER scope on Registry"
    if ($oldUserPSModulePathForRegistry -ne $newUserPSModulePathForRegistry) {
        Write-Output "Setting USER scope PSModulePath on Registry."
        [Environment]::SetEnvironmentVariable('PSModulePath', $newUserPSModulePathForRegistry, 'User')
    }
    FixJsonConfigFile
} elseif ($IsLinux) {
    FixJsonConfigFile
} elseif ($IsMacOS) {
    FixJsonConfigFile
} else {
    Write-Warning "PSModule setup is not implemented for this platform '$([System.Environment]::OSVersion.Platform)' (send a PR!)"
    $false
}

function ModuleMissing([Parameter(Mandatory = $true)][string]$moduleName, [System.Version]$minimumVersion) {
    if ($null -eq $minimumVersion) {
        ([array]($env:PSModulePath.Split([System.IO.Path]::PathSeparator, [System.StringSplitOptions]::RemoveEmptyEntries) | `
                ForEach-Object { Join-Path $_ $moduleName } | `
                Where-Object { Test-Path $_ }
        ))?.Count -eq 0
    } else {
        ([array]($env:PSModulePath.Split([System.IO.Path]::PathSeparator, [System.StringSplitOptions]::RemoveEmptyEntries) | `
                ForEach-Object { Join-Path $_ $moduleName } | `
                Where-Object { Test-Path $_ } | `
                Where-Object { (Get-Module -ListAvailable $_).Version -ge $minimumVersion } `
        ))?.Count -eq 0
    }
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

if (ModuleMissing Pester '5.0.0') {
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

if (ModuleMissing PSReadLine '2.2.6') {
    Save-Module PSReadLine $localModulesDirectory -Confirm:$false
}

Remove-Item -Path Function:\FixPSModulePath
