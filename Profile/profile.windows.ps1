$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    Write-Error "Cannot run this script, needs to source it."
    exit 1
}
if (!$IsWindows) {
    Write-Warning "This script ($PSCommandPath) is only for Windows."
    exit
}
$script:profileDir = $PSScriptRoot

# disable Telemetry to be able to use this in PowerShell Core
# see https://docs.microsoft.com/en-us/visualstudio/ide/visual-studio-experience-improvement-program
# and https://developercommunity.visualstudio.com/idea/663594/microsoftvisualstudiodevshell-doesnt-work-with-pow.html
# Or uncomment the following line:
# if ($PSVersionTable.PSEdition -eq 'Desktop') { return }
function vs() {
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
            Enter-VsDevShell -VsInstallPath $vsPath
        } else {
            Write-Output "DevShell dll not found at '$devshellDllPath'"
        }
    } else {
        Write-Output "Visual Studio not found."
    }
}

$env:ChocolateyToolsRoot = "c:\tools\"
$env:ChocolateyBinRoot = "c:\tools\"

. "$profileDir/CreateAliases.windows.ps1"

if (!(Get-Process ssh-agent -ErrorAction Ignore) -and (Test-Path (Join-Path (Join-Path $(if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }) .ssh) id_rsa))) {
    Start-SshAgent -Quiet
}
if (Get-Command colortool -ErrorAction Ignore) { colortool --quiet campbell.ini }
