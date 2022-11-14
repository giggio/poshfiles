#Requires -RunAsAdministrator
#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

# docker
$dockerConfigFilePath = "$env:USERPROFILE\.docker\daemon.json"
$dockerConfig = Get-Content $dockerConfigFilePath | ConvertFrom-Json
$dockerConfig | Add-Member -MemberType NoteProperty -Name "experimental" -Value $true -Force
$dockerConfig | Add-Member -MemberType NoteProperty -Name "max-concurrent-downloads" -Value 10 -Force
$dockerConfig | Add-Member -MemberType NoteProperty -Name "max-concurrent-uploads" -Value 10 -Force
$dockerConfig | ConvertTo-Json | Out-File $dockerConfigFilePath
