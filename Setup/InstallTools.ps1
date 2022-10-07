$ErrorActionPreference = 'stop'
$localModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Modules)
$bin = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) bin)
$env:PATH += $([System.IO.Path]::PathSeparator) + $bin
if (!(Test-Path $bin/tflint*)) {
    $os = ''
    if ($IsWin) {
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

if ($IsWin) {
    if (Get-Command fzf -ErrorAction Ignore) {
        function CreateFzfPsm1() {
            if (!(Test-Path "$localModulesDirectory/PSFzf/PSFzf.psm1")) {
                Write-Output "Creating $localModulesDirectory/PSFzf/PSFzf.psm1..."
                . "$localModulesDirectory/PSFzf/helpers/Join-ModuleFiles.ps1"
            }
        }
        if (!(Test-Path "$localModulesDirectory/PSFzf/PSFzf.dll")) {
            if (Get-Command dotnet -ErrorAction Ignore) {
                $fzfTempDir = Join-Path "$([System.IO.Path]::GetTempPath())" fzf
                New-Item -Type Directory $fzfTempDir -Force | Out-Null
                dotnet build --nologo --verbosity quiet --configuration Release --output $fzfTempDir "$localModulesDirectory/PSFzf/PSFzf-Binary/PSFzf-Binary.csproj"
                Copy-Item $fzfTempDir/PSFzf.dll "$localModulesDirectory/PSFzf/"
                CreateFzfPsm1
                Remove-Item -Force -Recurse $fzfTempDir
            }
        }
        CreateFzfPsm1
    }
}
