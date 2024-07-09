. "$PSScriptRoot/Common.ps1"

if ($IsWindows) {
    function time() {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        Invoke-Expression $($args -join ' ')
        $sw.Stop()
        $sw.elapsed
    } # call like: `time ls` or `time git log`
}

function Remove-FromPath {
    Param( [parameter(Mandatory = $true)][String]$pathToRemove)
    $exists = ($env:path.Split(';') | Where-Object { $_ -eq $pathToRemove })
    if (!$exists) {
        throw "Path not found."
    }
    $env:path = ($env:path.Split(';') | Where-Object { $_ -ne $pathToRemove }) -join ';'
}

function Test-Elevated {
    if ($IsWindows) {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } elseif ($IsLinux) {
        $(id -u) -eq 0
    } elseif ($IsMacOS) {
        Write-Warning "Test-Elevated is not implemented for MacOS (send a PR!)"
        $false
    } else {
        Write-Warning "Test-Elevated is not implemented for this platform '$([System.Environment]::OSVersion.Platform)' (send a PR!)"
        $false
    }
}

function Get-StrictMode {
    try { $x = @(1); $null = ($null -eq $x[2]) }
    catch { return 3 }

    try { "x".Year }
    catch { return 2 }

    try { $null = ($y -gt 1) }
    catch { return 1 }

    return 0
}

function Sync-Path {
    if ($IsWindows) {
        $userPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
        $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'User')
        $env:PATH = "$userPath;$machinePath"
    }
}

function Test-Error {
    if (!$?) {
        Write-Error "Error encountered. Last exit code was: $LASTEXITCODE."
    }
}

function Set-DnsClientServerAddressToCloudflare {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [switch]$Force
    )
    if ($Force -and -not $Confirm) { $ConfirmPreference = 'None' }

    [array]$nas = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }
    if ($nas.Count -eq 0) { throw 'No up interface found.' }
    $na = $null
    foreach ($na in $nas) {
        $newServers = @()
        if (Get-NetIPAddress -InterfaceIndex $na.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue) {
            if (Get-NetIPAddress -InterfaceIndex $na.ifIndex -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' }) {
                $newServers += '1.1.1.1', '8.8.8.8'
            }
        }
        if (Get-NetIPAddress -InterfaceIndex $na.ifIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue) {
            if (Get-NetIPAddress -InterfaceIndex $na.ifIndex -AddressFamily IPv6 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' }) {
                $newServers += '2606:4700:4700::1111', '2606:4700:4700::1001'
            }
        }
        if ($newServers.Count -gt 0) {
            if ($PSCmdlet.ShouldProcess("Performing ``Set-DnsClientServerAddress -InterfaceIndex $($na.ifIndex) -ServerAddresses $($newServers -join ',')`` (Interface '$($na.Name)')", $na.ifIndex, 'Set-DnsClientServerAddress')) {
                Set-DnsClientServerAddress -InterfaceIndex $na.ifIndex -ServerAddresses $newServers
            }
        }
    }
}

function Reset-DnsClientServerAddress {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [switch]$Force
    )
    if ($Force -and -not $Confirm) { $ConfirmPreference = 'None' }

    [array]$nas = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }
    if ($nas.Count -eq 0) { throw 'No up interface found.' }
    $na = $null
    foreach ($na in $nas) {
        if (Get-NetIPAddress -InterfaceIndex $na.ifIndex | Where-Object { $_.PrefixOrigin -eq 'Dhcp' }) {
            if ($PSCmdlet.ShouldProcess("Performing ``Set-DnsClientServerAddress -InterfaceIndex $($na.ifIndex) -ResetServerAddresses`` (Interface '$($na.Name)')", $na.ifIndex, 'Set-DnsClientServerAddress')) {
                Set-DnsClientServerAddress -InterfaceIndex $na.ifIndex -ResetServerAddresses
            }
        }
    }
}
