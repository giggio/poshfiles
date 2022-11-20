# shim/patch missing properties in Windows PowerShell
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    if (!(Test-Path Variable:\IsWindows)) {
        $global:IsWindows = [System.PlatformID]::Win32NT, [System.PlatformID]::Win32S, [System.PlatformID]::Win32Windows, [System.PlatformID]::Win32Windows, [System.PlatformID]::WinCE, [System.PlatformID]::Xbox -contains [System.Environment]::OSVersion.Platform
        $global:IsMacOS = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::MacOSX
        $global:IsLinux = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Unix
    }
}
