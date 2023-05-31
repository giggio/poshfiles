#Requires -RunAsAdministrator
#Requires -PSEdition Desktop
$ErrorActionPreference = 'stop'

. $PSScriptRoot\Utils-WindowsPowerShell.ps1

# download and install caskaydia cove font
Install-FontWindows -Url 'https://github.com/ryanoasis/nerd-fonts/raw/v2.3.3/patched-fonts/CascadiaCode/Regular/complete/Caskaydia%20Cove%20Nerd%20Font%20Complete%20Windows%20Compatible%20Regular.otf' # todo: update to 3.0
