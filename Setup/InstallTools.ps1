#Requires -RunAsAdministrator
#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

$ErrorActionPreference = 'stop'
$script:localModulesDirectory = Resolve-Path (Join-Path $PSScriptRoot .. Modules)

$bin = Resolve-Path (Join-Path $PSScriptRoot .. bin)
$env:PATH += $([System.IO.Path]::PathSeparator) + $bin
if (!(Test-Path $bin/tflint*)) {
    $os = ''
    if ($IsWindows) {
        $os = 'windows'
    } elseif ($IsLinux) {
        $os = 'linux'
        return # let's not support Linux yet, it blows up
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tmpFile = (New-TemporaryFile).FullName
    Invoke-WebRequest "https://github.com/wata727/tflint/releases/download/v0.7.0/tflint_$($os)_amd64.zip" -OutFile $tmpFile
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpFile, $bin)
    Remove-Item $tmpFile
}

if ($IsWindows) {
    . "$PSScriptRoot/InstallTools-Windows.ps1"
}
