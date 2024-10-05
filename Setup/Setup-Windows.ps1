#Requires -RunAsAdministrator
#Requires -PSEdition Core
#Requires -Version 7.2

if (!$IsWindows) {
    Write-Warning "This script ($PSCommandPath) is only for Windows."
    exit 1
}

$script:rootDir = Resolve-Path (Join-Path $PSScriptRoot ..)
$script:profileDir = Join-Path $rootDir Profile
. "$profileDir/Functions.ps1"
$script:setupDir = $PSScriptRoot
Sync-Path
powershell.exe -ExecutionPolicy RemoteSigned -File "$setupDir/Configure-WindowsPowerShell.ps1"
Test-Error

. "$setupDir/WindowsDefenderExclusions.ps1"
Add-WindowsDefenderExclusions
. "$setupDir/Configure-Windows.ps1"


$actionName = "Start process explorer"
if ($null -eq (Get-ScheduledTask $actionName -ErrorAction SilentlyContinue)) {
    $procExpPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\procexp.exe"
    $procexpCmd = Get-Command procexp -ErrorAction SilentlyContinue
    if ($null -ne $procexpCmd) {
        $procExpPath = $procexpCmd.Source
    }
    if (Test-Path $procExpPath) {
        $action = New-ScheduledTaskAction -Execute "$procExpPath"
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $(whoami)
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -Compatibility Win8 -MultipleInstances IgnoreNew -StartWhenAvailable -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Seconds 0)
        $principal = New-ScheduledTaskPrincipal -LogonType Interactive -RunLevel Highest -UserId $(whoami) -ProcessTokenSidType Default
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Description "$actionName" -Settings $settings -Principal $principal
        Register-ScheduledTask -InputObject $task -TaskName $actionName -TaskPath $env:USERNAME -User $(whoami) | Out-Null
    }
}

if (Get-Command gpgconf -ErrorAction SilentlyContinue) {
    $actionName = "Start gpg-agent"
    if ($null -eq (Get-ScheduledTask $actionName -ErrorAction SilentlyContinue)) {
        $action = New-ScheduledTaskAction -Execute "%windir%\system32\cmd.exe" -Argument "/C start `"Starting gpg agent...`" /MIN /WAIT gpgconf --launch gpg-agent"
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $(whoami)
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -Compatibility Win8 -MultipleInstances IgnoreNew -StartWhenAvailable -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Seconds 0)
        $principal = New-ScheduledTaskPrincipal -LogonType Interactive -RunLevel Limited -UserId $(whoami) -ProcessTokenSidType Default
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Description "$actionName" -Settings $settings -Principal $principal
        Register-ScheduledTask -InputObject $task -TaskName $actionName -TaskPath $env:USERNAME -User $(whoami) | Out-Null
    }
}

$ssha = Get-Service ssh-agent -ErrorAction SilentlyContinue
if ($null -ne $ssha) {
    # set ssh-agent to start manually, as we're using gpg-agent for ssh
    if ($ssha.StartType -ne 'Manual') {
        Write-Output "Setting ssh-agent to manual."
        Set-Service $ssha -StartMode Manual
    }
}

if (Test-Path "$env:ProgramFiles\Git\usr\bin") {
    # git tools
    if ($env:path.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0) {
        Write-Output "Setting local PATH to use Git tools."
        $env:PATH = "$env:PATH;$env:ProgramFiles\Git\usr\bin"
    }
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    if ($machinePath.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0) {
        Write-Output "Setting machine PATH to use Git tools."
        [Environment]::SetEnvironmentVariable('PATH', "$machinePath;$env:ProgramFiles\Git\usr\bin", 'Machine')
    }
}

$allowInsecureGuestAuth = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters -Name AllowInsecureGuestAuth -ErrorAction SilentlyContinue
if (($null -eq $allowInsecureGuestAuth) -or $allowInsecureGuestAuth.AllowInsecureGuestAuth -ne 1) {
    # see for more info: https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/guest-access-in-smb2-is-disabled-by-default
    Write-Output "Allowing insecure guest authentication to network shares."
    Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters -Name AllowInsecureGuestAuth -Value 1 -Type DWord
}
