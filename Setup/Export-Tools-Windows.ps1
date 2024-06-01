if ((Get-Command git).CommandType -eq 'Alias') { # todo: remove when https://github.com/ScoopInstaller/Scoop/issues/5196 is fixed
    Remove-Alias git
}
scoop export --config | jq -r -e --sort-keys 'del(.apps[].Updated) | del(.buckets[].Updated)' | Out-File $PSScriptRoot\scoopfile.json
choco export --output-file-path=$PSScriptRoot\choco-export.config
if (Test-Path $PSScriptRoot\choco-export.config.backup) {
    Remove-Item $PSScriptRoot\choco-export.config.backup
}

$wingetPcJson = Get-Content $PSScriptRoot\winget-pc.json | ConvertFrom-Json
$packagesToIgnore = $wingetPcJson.Sources[0].Packages.PackageIdentifier

$wingetNotebookDellJson = Get-Content $PSScriptRoot\winget-notebook-dell.json | ConvertFrom-Json
$packagesToIgnore += $wingetNotebookDellJson.Sources[0].Packages.PackageIdentifier

winget export --output $PSScriptRoot\winget.json
$wingetJson = Get-Content $PSScriptRoot\winget.json | ConvertFrom-Json
[array]$wingetJson.Sources = $wingetJson.Sources | Sort-Object { $_.SourceDetails.Name }
$wingetJson.Sources | ForEach-Object { [array]$_.Packages = $_.Packages | Sort-Object -Property PackageIdentifier -Unique | Where-Object { $_.PackageIdentifier -notin $packagesToIgnore } }
$wingetJson | ConvertTo-Json -Depth 100 | Out-File $PSScriptRoot\winget.json

