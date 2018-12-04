function color ($lexer = 'javascript') {
    Begin { $t = "" }
    Process {
        $t = "$t
    $_"
    }
    End { $t | pygmentize.exe -l $lexer -O style=vs -f console16m; }
} # call like: `docker inspect foo | color`

if ($isWin) {
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
