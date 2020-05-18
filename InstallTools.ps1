$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ErrorActionPreference = 'stop'
$bin = "$root/bin"
$env:PATH += $([System.IO.Path]::PathSeparator) + $bin
if (!(Test-Path $bin)) { New-Item -Type Directory $bin | Out-Null }
$os = ''
if ($IsWin) {
    $os = 'windows'
} elseif ($IsLinux) {
    $os = 'linux'
    return # let's not support Linux yet, it blows up
}
if (!(Test-Path $bin/tflint*)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tmpFile = (New-TemporaryFile).FullName
    Invoke-WebRequest "https://github.com/wata727/tflint/releases/download/v0.7.0/tflint_$($os)_amd64.zip" -OutFile $tmpFile
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpFile, $bin)
    Remove-Item $tmpFile
}

if ($IsWin) {
    if (Get-Command fzf -ErrorAction Ignore) {
        function CreateFzfPsm1() {
          if (!(Test-Path "$root/Modules/PSFzf/PSFzf.psm1")) {
              Write-Host "Creating $root/Modules/PSFzf/PSFzf.psm1..."
              . "$root/Modules/PSFzf/helpers/Join-ModuleFiles.ps1"
          }
        }
        if (!(Test-Path "$root/Modules/PSFzf/PSFzf.dll")) {
            if (Get-Command dotnet -ErrorAction Ignore) {
                $fzfTempDir = Join-Path "$([System.IO.Path]::GetTempPath())" fzf
                New-Item -Type Directory $fzfTempDir -Force | Out-Null
                dotnet build --nologo --verbosity quiet --configuration Release --output $fzfTempDir "$root/Modules/PSFzf/PSFzf-Binary/PSFzf-Binary.csproj"
                Copy-Item $fzfTempDir/PSFzf.dll "$root/Modules/PSFzf/"
                CreateFzfPsm1
                Import-Module "$root/Modules/PSFzf/PSFzf.psd1" -ArgumentList 'Ctrl+t', 'Ctrl+r' -Force
                Remove-Item -Force -Recurse $fzfTempDir
            }
        }
        CreateFzfPsm1
    }
}
