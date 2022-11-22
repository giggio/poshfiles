$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    Write-Error "Cannot run this script, needs to source it."
    exit 1
}

# shim/patch missing properties in Windows PowerShell
function Repair-GlobalVariables {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', "", Scope = 'function', Justification = 'We are shimming missing properties in Windows PowerShell')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', "", Scope = 'function', Justification = 'These are global variables.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', "", Scope = 'function', Justification = 'We are repairing more than one.')]
    param()
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        if (!(Test-Path Variable:\IsWindows)) {
            $global:IsWindows = [System.PlatformID]::Win32NT, [System.PlatformID]::Win32S, [System.PlatformID]::Win32Windows, [System.PlatformID]::Win32Windows, [System.PlatformID]::WinCE, [System.PlatformID]::Xbox -contains [System.Environment]::OSVersion.Platform
            $global:IsMacOS = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::MacOSX
            $global:IsLinux = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Unix
        }
    }
}
Repair-GlobalVariables
Remove-Item -Path Function:\Repair-GlobalVariables
