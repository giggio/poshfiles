scoop export --config | jq  -r -e --sort-keys . | Out-File $PSScriptRoot\scoopfile.json
choco export --output-file-path=$PSScriptRoot\choco-export.config
if (Test-Path $PSScriptRoot\choco-export.config.backup) {
    Remove-Item $PSScriptRoot\choco-export.config.backup
}
winget export --output $PSScriptRoot\winget.json
$wingetJson = Get-Content $PSScriptRoot\winget.json | ConvertFrom-Json
[array]$wingetJson.Sources = $wingetJson.Sources | Sort-Object { $_.SourceDetails.Name }
$wingetJson.Sources | ForEach-Object { [array]$_.Packages = $_.Packages | Sort-Object -Property PackageIdentifier -Unique }
$wingetJson | ConvertTo-Json -Depth 100 | Out-File $PSScriptRoot\winget.json
