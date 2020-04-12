$i = 1
$s = Get-Date
$pre = ''
function crono() {
    Write-Host $pre"#"($script:i++)
    "{0:n0}" -f ((Get-Date) - $script:s).TotalMilliseconds
    $script:s = Get-Date
    # Get-Date -Format 'm:ss:fff'
    Write-Host ""
}