scoop export | Out-File $PSScriptRoot\scoopfile.json
choco export --output-file-path=$PSScriptRoot\choco-export.config
winget export --output $PSScriptRoot\winget.json
