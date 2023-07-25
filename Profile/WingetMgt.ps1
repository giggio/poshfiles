#Requires -PSEdition Core
#Requires -Version 7.2
#Requires -Modules Microsoft.WinGet.Client
Set-StrictMode -Version 3.0

$ErrorActionPreference = 'stop'

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    Write-Error "Cannot run this script, needs to source it."
    exit 1
}

if (!$IsWindows) {
    Write-Warning "This script ($PSCommandPath) is only for Windows."
    exit
}

function Update-WingetPackages {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', "", Scope = 'function', Justification = 'I like it like this.')]
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [switch]$IncludePinned
    )
    if ($IncludePinned) {
        $pkgs = Get-WingetPackageUpdate -IncludePinned
    } else {
        $pkgs = Get-WingetPackageUpdate
    }
    $pkgs | ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.Id, "Update Windows package")) {
            Update-WinGetPackage -Id $_.Id -Confirm:$false | Out-Null
        }
    }
}

function Get-WingetPackageUpdate {
    param
    (
        [switch]$IncludePinned
    )
    $pkgsToUpdate = Get-WinGetPackage | Where-Object { $_.IsUpdateAvailable -and $_.InstalledVersion.Version -ne 'Unknown' }
    [array]$pinnedItems = Get-PinnedWingetPackages
    if (!$IncludePinned) {
        [array]$pkgsToUpdate = $pkgsToUpdate | Where-Object { $pinnedItems.Id -notcontains $_.Id }
    }
    return $pkgsToUpdate
}

function Add-WingetPackagePin {
    Param( [parameter(Mandatory = $true)][String]$packageId)
    if (!(Get-WinGetPackage | Where-Object { $_.Id -eq $packageId })) {
        Write-Error "Package '$packageId' is not installed."
        return
    }
    $pinnedItems = Get-PinnedWingetPackages
    if ($pinnedItems | Where-Object { $_.Id -eq $packageId }) {
        Write-Warning "Package '$packageId' is already pinned."
        return
    }
    $pinnedItems = @(@{ Id = $packageId }) + $pinnedItems | Sort-Object -Property Id
    $pinFile = $PSScriptRoot + "\winget-pinned.json"
    $pinnedItems | ConvertTo-Json -Depth 2 -AsArray | Set-Content -Path $pinFile -Force
}

function Remove-WingetPackagePin {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', "", Scope = 'function', Justification = 'It is just like Add, so I dont need it.')]
    param
    (
        [parameter(Mandatory = $true)][String]$packageId
    )
    [array]$pinnedItems = Get-PinnedWingetPackages
    $pinnedPkg = $pinnedItems | Where-Object { $_.Id -eq $packageId }
    if (!$pinnedPkg) {
        Write-Warning "Package '$packageId' was already not pinned."
        return
    }
    $pinnedItems = $pinnedItems | Where-Object { $_.Id -ne $packageId }
    $pinFile = $PSScriptRoot + "\winget-pinned.json"
    if ($null -eq $pinnedItems) {
        Set-Content -Path $pinFile -Force -Value '[]'
    } else {
        $pinnedItems | ConvertTo-Json -Depth 2 -AsArray | Set-Content -Path $pinFile -Force
    }
}

function Clear-WingetPackagePin {
    $pinFile = $PSScriptRoot + "\winget-pinned.json"
    Set-Content -Path $pinFile -Force -Value '[]'
}

function Get-PinnedWingetPackages {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', "", Scope = 'function', Justification = 'I like it like this.')]
    param ()
    $pinFile = $PSScriptRoot + "\winget-pinned.json"
    if (!(Test-Path $pinFile)) {
        New-Item -ItemType File -Path $pinFile -Force -Value '[]' | Out-Null
    }
    [array]$pinnedItems = Get-Content -Path $pinFile -Raw | ConvertFrom-Json
    if ($null -eq $pinnedItems) {
        $pinnedItems = @()
    }
    $pinnedItems
}
