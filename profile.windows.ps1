$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Import-Module $root\Modules\z\z.psm1

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        [array]$vss = . $vswhere -version 16 -property installationpath
        if ($vss.Count -ne 0) {
            $vsPath = $vss[0]
        }
    }
    elseif (Get-Module VSSetup) {
        [array]$vss = Get-VSSetupInstance | Where-Object { $_.InstallationVersion.Major -ge 17 } | Select-Object -Property InstallationPath -First 1
        if ($vss.Count -ne 0) {
            $vsPath = $vss[0].InstallationPath
        }
    }
    if ($vsPath) {
        Import-Module "$vsPath\Common7\Tools\vsdevshell\Microsoft.VisualStudio.DevShell.dll"
        Enter-VsDevShell -VsInstallPath $vsPath > $null
    }
}
