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

#gpg/pgp import public key, so it works with yubikey
$gpgPublicKeyFile = "$env:temp/key.asc"
$gpgOwnerTrustFile = "$env:temp/ownertrust.txt"
Invoke-WebRequest "https://links.giggio.net/pgp" -OutFile $gpgPublicKeyFile
Set-Content -Path $gpgOwnerTrustFile -Value "275F6749AFD2379D1033548C1237AB122E6F4761:6:"
gpg --import $gpgPublicKeyFile
gpg --import-ownertrust $gpgOwnerTrustFile
Remove-Item $gpgPublicKeyFile
Remove-Item $gpgOwnerTrustFile
# set gpg-config so it works with wsl-ssh-pageant
Write-Output 'enable-ssh-support:0:1' | gpgconf --change-options gpg-agent
Write-Output 'enable-putty-support:0:1' | gpgconf --change-options gpg-agent
Write-Output 'max-cache-ttl:0:34560000' | gpgconf --change-options gpg-agent
Write-Output 'default-cache-ttl:0:34560000' | gpgconf --change-options gpg-agent
$gpgAgentConfigPath = "$env:APPDATA/gnupg/gpg-agent.conf"
Get-Content $gpgAgentConfigPath
gpgconf --reload
gpgconf --kill gpg-agent
gpg-connect-agent /bye
