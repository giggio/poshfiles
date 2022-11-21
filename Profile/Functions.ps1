. "$PSScriptRoot/Common.ps1"

function color ($lexer = 'javascript') {
    Begin { $t = "" }
    Process {
        $t = "$t
    $_"
    }
    End { $t | pygmentize.exe -l $lexer -O style=vs -f console16m; }
} # call like: `docker inspect foo | color`

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
        $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
        $env:PATH = "$userPath;$machinePath"
    }
}
