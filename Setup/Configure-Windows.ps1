#Requires -RunAsAdministrator
#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

# enable long paths
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

# docker
$dockerConfigFilePath = "$env:USERPROFILE\.docker\daemon.json"
if (Test-Path $dockerConfigFilePath) {
    $dockerConfig = Get-Content $dockerConfigFilePath | ConvertFrom-Json
    $dockerConfig | Add-Member -MemberType NoteProperty -Name "experimental" -Value $true -Force
    $dockerConfig | Add-Member -MemberType NoteProperty -Name "max-concurrent-downloads" -Value 10 -Force
    $dockerConfig | Add-Member -MemberType NoteProperty -Name "max-concurrent-uploads" -Value 10 -Force
    $dockerConfig | ConvertTo-Json | Out-File $dockerConfigFilePath
}

# windows explorer, show file extensions
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -Value 0

# The Windows OpenSSH ssh-agent service owns the named pipe '\\.\pipe\openssh-ssh-agent'.
# gpg-agent needs that very same pipe for its 'enable-win32-openssh-support' option (set below),
# and when the pipe is already taken gpg-agent just carries on without openssh support, so the
# yubikey authentication key silently never shows up in `ssh-add -l`. We use gpg-agent as the ssh
# agent, so the service is disabled here, and it has to be stopped *before* gpg-agent is
# (re)started further down, otherwise gpg-agent still finds the pipe occupied.
$script:stoppedSshAgentService = $false
$sshAgentService = Get-Service ssh-agent -ErrorAction Ignore
if ($null -ne $sshAgentService) {
    if ($sshAgentService.StartType -ne 'Disabled') {
        Write-Output "Disabling the Windows ssh-agent service, gpg-agent is used as the ssh agent."
        Set-Service -Name ssh-agent -StartupType Disabled
    }
    if ($sshAgentService.Status -ne 'Stopped') {
        Write-Output "Stopping the Windows ssh-agent service so gpg-agent can own '\\.\pipe\openssh-ssh-agent'."
        Stop-Service -Name ssh-agent -Force
        $stoppedSshAgentService = $true
    }
}

#gpg/pgp import public key, so it works with yubikey
if (Get-Command gpg -ErrorAction Ignore) {
    $keyId = '275F6749AFD2379D1033548C1237AB122E6F4761'
    if (!((gpg --list-keys $keyId | Where-Object { $_.StartsWith('uid') }) ?? '').Contains('[ultimate]')) {
        $gpgPublicKeyFile = "$env:temp/key.asc"
        $gpgOwnerTrustFile = "$env:temp/ownertrust.txt"
        Invoke-WebRequest "https://links.giggio.net/pgp" -OutFile $gpgPublicKeyFile
        Set-Content -Path $gpgOwnerTrustFile -Value "${keyId}:6:"
        gpg --import $gpgPublicKeyFile
        gpg --import-ownertrust $gpgOwnerTrustFile
        Remove-Item $gpgPublicKeyFile
        Remove-Item $gpgOwnerTrustFile
    }
    # set gpg-config so it works with ssh and wsl
    $gpgAgentConf = $(gpgconf --list-options gpg-agent)
    # freeing the openssh pipe above only takes effect once gpg-agent restarts and claims it
    $updatedGpgAgentConf = $stoppedSshAgentService
    if (!($gpgAgentConf | Where-Object { $_.StartsWith('enable-ssh-support:') }).EndsWith(':1')) {
        Write-Output 'enable-ssh-support:0:1' | gpgconf --change-options gpg-agent
        $updatedGpgAgentConf = $true
    }
    if (!($gpgAgentConf | Where-Object { $_.StartsWith('enable-putty-support:') }).EndsWith(':1')) {
        Write-Output 'enable-putty-support:0:1' | gpgconf --change-options gpg-agent
        $updatedGpgAgentConf = $true
    }
    if (!($gpgAgentConf | Where-Object { $_.StartsWith('max-cache-ttl:') }).EndsWith(':34560000')) {
        Write-Output 'max-cache-ttl:0:34560000' | gpgconf --change-options gpg-agent
        $updatedGpgAgentConf = $true
    }
    if (!($gpgAgentConf | Where-Object { $_.StartsWith('default-cache-ttl:') }).EndsWith(':34560000')) {
        Write-Output 'default-cache-ttl:0:34560000' | gpgconf --change-options gpg-agent
        $updatedGpgAgentConf = $true
    }
    $gpgAgentConfigPath = "$env:APPDATA/gnupg/gpg-agent.conf"
    $gpgAgentConfig = Get-Content $gpgAgentConfigPath
    if (!($gpgAgentConfig | Where-Object { $_.StartsWith('enable-win32-openssh-support') })) {
        # this will create named pipe '\\.\pipe\openssh-ssh-agent'
        # todo: gpgconf is not working, it fails with 'gpgconf: unknown option enable-win32-openssh-support', change to use gpgconf when it works
        # should be: Write-Output 'enable-win32-ssh-support:0:1' | gpgconf --change-options gpg-agent
        $gpgAgentConfig += "enable-win32-openssh-support"
        $gpgAgentConfig | Out-File $gpgAgentConfigPath
        $updatedGpgAgentConf = $true
    }
    if ($updatedGpgAgentConf) {
        Get-Content $gpgAgentConfigPath
        gpgconf --reload
        gpgconf --kill gpg-agent
        gpg-connect-agent /bye
    }
    # gpg-agent claims the openssh pipe lazily on startup, so make sure it actually got it,
    # otherwise ssh silently falls back to having no keys at all
    $sshAdd = Get-Command ssh-add -CommandType Application -ErrorAction Ignore | Select-Object -First 1
    if ($sshAdd) {
        $agentKeys = $null
        foreach ($attempt in 1..5) {
            $agentKeys = & $sshAdd -L 2>&1
            if ($LASTEXITCODE -eq 0) { break }
            Start-Sleep -Milliseconds 500
        }
        if (($agentKeys | Where-Object { $_ -match 'openpgp:|cardno:' })) {
            Write-Output "gpg-agent is serving the yubikey authentication key over '\\.\pipe\openssh-ssh-agent'."
        } else {
            Write-Warning "'\\.\pipe\openssh-ssh-agent' is not offering a yubikey key. Plug the yubikey in and run 'gpgconf --kill gpg-agent; gpg-connect-agent /bye', and check that the ssh-agent service is still stopped."
        }
    }
} else {
    Write-Host "Gpg not installed, configuration not performed."
}

$script:symbolsPath = "$env:HOMEDRIVE\symbols"
if (!(Test-Path $symbolsPath)) {
    mkdir $symbolsPath
}
$machinePath = [Environment]::GetEnvironmentVariable('_NT_SYMBOL_PATH', 'Machine')
if (!($machinePath)) {
    Write-Output "Setting machine environment variable _NT_SYMBOL_PATH to use symbol path '$symbolsPath'."
    [Environment]::SetEnvironmentVariable('_NT_SYMBOL_PATH', "cache*$symbolsPath;SRV*c:\symbols*http://msdl.microsoft.com/download/symbols", 'Machine')
}

# setup WSL communication with Hyper-V local VMs
# see https://stackoverflow.com/a/75684131/2723305
# and https://techcommunity.microsoft.com/t5/itops-talk-blog/windows-subsystem-for-linux-2-addressing-traffic-routing-issues/ba-p/1764074
# todo: maybe setting networkingMode to 'mirrored' will solve this, but it is experimental at this moment and it is causing problems
# with Docker port forwarding. See: https://learn.microsoft.com/en-us/windows/wsl/wsl-config#experimental-settings
Get-NetIPInterface | where {$_.InterfaceAlias -match 'vEthernet \(WSL' -or $_.InterfaceAlias -eq 'vEthernet (Default Switch)'} | Set-NetIPInterface -Forwarding Enabled
