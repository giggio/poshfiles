#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

$script:setupDir = $PSScriptRoot

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if ($isDotSourced) {
    Write-Error "This script must not be sourced."
    return
}

if (Test-Elevated) {
    Write-Error "This script must not be run as administrator."
    exit 1
}

if (!($IsWindows)) {
    Write-Error "This script must be run on Windows."
    exit 1
}

$createGitConfig = $true
if (Test-Path $env:USERPROFILE/.gitconfig) {
    if ((Get-Item $env:USERPROFILE/.gitconfig).LinkType -eq 'SymbolicLink') {
        if ((Get-Item $env:USERPROFILE/.gitconfig).Target -eq (Get-Item $PSScriptRoot/../home/.gitconfig)) {
            $createGitConfig = $false
        } else {
            Remove-Item $env:USERPROFILE/.gitconfig
        }
    } else {
        Move-Item $env:USERPROFILE/.gitconfig $env:USERPROFILE/.gitconfig.backup -Force
    }
}
if ($createGitConfig) {
    New-Item -ItemType SymbolicLink -Target $PSScriptRoot/../home/.gitconfig -Path $env:USERPROFILE/.gitconfig
}

$createGitAttributes = $true
if (Test-Path $env:USERPROFILE/.gitattributes) {
    if ((Get-Item $env:USERPROFILE/.gitattributes).LinkType -eq 'SymbolicLink') {
        if ((Get-Item $env:USERPROFILE/.gitattributes).Target -eq (Get-Item $PSScriptRoot/../home/.gitattributes)) {
            $createGitAttributes = $false
        } else {
            Remove-Item $env:USERPROFILE/.gitattributes
        }
    } else {
        Move-Item $env:USERPROFILE/.gitattributes $env:USERPROFILE/.gitattributes.backup -Force
    }
}
if ($createGitAttributes) {
    New-Item -ItemType SymbolicLink -Target $PSScriptRoot/../home/.gitattributes -Path $env:USERPROFILE/.gitattributes
}

$createNeovimConfig = $true
if (Test-Path "$env:USERPROFILE\AppData\Local\nvim") {
    if ((Get-Item "$env:USERPROFILE\AppData\Local\nvim").LinkType -eq 'SymbolicLink') {
        if ((Get-Item "$env:USERPROFILE\AppData\Local\nvim").Target -eq (Get-Item "$env:USERPROFILE\.vim")) {
            $createNeovimConfig = $false
        } else {
            Remove-Item "$env:USERPROFILE\AppData\Local\nvim"
        }
    } else {
        Move-Item "$env:USERPROFILE\AppData\Local\nvim" "$env:USERPROFILE\AppData\Local\nvim.backup " -Force
    }
}
if ($createNeovimConfig) {
    New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\AppData\Local\nvim" -Value "$env:USERPROFILE\.vim"
}

& "$setupDir/Configure-Windows-Wsl.ps1"
