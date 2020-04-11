$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ErrorActionPreference = 'stop'
$bin = "$root\bin"
$env:PATH += $([System.IO.Path]::PathSeparator) + $bin
if (!(Test-Path $bin)) { New-Item -Type Directory $bin | Out-Null }
$os = ''
if ($IsWin) {
    $os = 'windows'
} elseif ($IsLinux) {
    $os = 'linux'
    return # let's not support Linux yet, it blows up
}
if (!(Test-Path $bin\tflint*)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tmpFile = (New-TemporaryFile).FullName
    Invoke-WebRequest "https://github.com/wata727/tflint/releases/download/v0.7.0/tflint_$($os)_amd64.zip" -OutFile $tmpFile
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpFile, $bin)
    Remove-Item $tmpFile
}
