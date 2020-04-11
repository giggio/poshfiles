#log history
$historyFilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) .ps_history
if (Test-Path $historyFilePath) {
    $numberOfPreviousCommands = $(Get-Content $historyFilePath | Measure-Object -Line).Lines - 1
} else {
    $numberOfPreviousCommands = 1
}
Register-EngineEvent PowerShell.Exiting -Action {
    $history = Get-History
    $filteredHistory = $history[($numberOfPreviousCommands - 1)..($history.Length - 2)]
    $filteredHistory | Export-Csv $historyFilePath -Append
} | Out-Null
if (Test-Path $historyFilePath) { Import-Csv $historyFilePath | Add-History }
