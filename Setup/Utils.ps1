#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    Write-Error "This script has to be sourced."
    exit 1
}

# add setup utils functions here
