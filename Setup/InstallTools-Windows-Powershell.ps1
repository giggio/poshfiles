#Requires -RunAsAdministrator
#Requires -PSEdition Desktop
$ErrorActionPreference = 'stop'

. $PSScriptRoot\Utils-WindowsPowerShell.ps1

# download and install caskaydia cove font
$fontFile = "$env:temp/CaskaydiaCove.otf"
Invoke-WebRequest 'https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Regular/complete/Caskaydia%20Cove%20Nerd%20Font%20Complete%20Windows%20Compatible%20Regular.otf' -OutFile $fontFile
Install-FontWindows "$fontFile"
Remove-Item $fontFile
