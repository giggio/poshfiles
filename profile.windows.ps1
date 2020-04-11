$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Import-Module $root\Modules\z\z.psm1

# disable Telemetry to be able to use this in PowerShell Core
# see https://docs.microsoft.com/en-us/visualstudio/ide/visual-studio-experience-improvement-program
# and https://developercommunity.visualstudio.com/idea/663594/microsoftvisualstudiodevshell-doesnt-work-with-pow.html
# Or uncomment the following line:
# if ($PSVersionTable.PSEdition -eq 'Desktop') { return }
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    [array]$vss = . $vswhere -version 16 -property installationpath
    if ($vss.Count -ne 0) {
        $vsPath = $vss[0]
    }
} elseif (Get-Module VSSetup) {
    [array]$vss = Get-VSSetupInstance | Where-Object { $_.InstallationVersion.Major -ge 17 } | Select-Object -Property InstallationPath -First 1
    if ($vss.Count -ne 0) {
        $vsPath = $vss[0].InstallationPath
    }
}
if ($vsPath) {
    $devshellDllPath = "$vsPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    if (Test-Path $devshellDllPath) {
        Import-Module $devshellDllPath
        Enter-VsDevShell -VsInstallPath $vsPath > $null
    } else {
        Write-Host "DevShell dll not found at '$devshellDllPath'"
    }
}

if (Get-Command fzf -ErrorAction Ignore) {
    if (Test-Path "$root/Modules/PSFzf/PSFzf.dll") {
        Import-Module "$root/Modules/PSFzf/PSFzf.psd1" -ArgumentList 'Ctrl+t', 'Ctrl+r' -Force
    } else {
        if (Get-Command dotnet -ErrorAction Ignore) {
            $fzfTempDir = Join-Path "$([System.IO.Path]::GetTempPath())" fzf
            New-Item -Type Directory $fzfTempDir -Force | Out-Null
            dotnet build --nologo --verbosity quiet --configuration Release --output $fzfTempDir "$root/Modules/PSFzf/PSFzf-Binary/PSFzf-Binary.csproj"
            Copy-Item $fzfTempDir/PSFzf.dll "$root/Modules/PSFzf/"
            Import-Module "$root/Modules/PSFzf/PSFzf.psd1" -ArgumentList 'Ctrl+t', 'Ctrl+r' -Force
            Remove-Item -Force -Recurse $fzfTempDir
        }
    }
    Set-PsFzfOption -TabExpansion -GitKeyBindings
}
