$script:localModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Modules)

$psakeTabExpansionFile = Join-Path (Join-Path $localModulesDirectory psake) PsakeTabExpansion.ps1
if (Test-Path $psakeTabExpansionFile) {
    . $psakeTabExpansionFile
}
if ((Test-Path Function:\TabExpansion) -and (-not (Test-Path Function:\DefaultTabExpansion))) {
    Rename-Item Function:\TabExpansion DefaultTabExpansion
}
# Set up tab expansion and include psake expansion
function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1]
    switch -regex ($lastBlock) {
        # Execute psake tab completion for all psake-related commands
        '(Invoke-psake|psake) (.*)' { PsakeTabExpansion $lastBlock }
        # Fall back on existing tab expansion
        default { DefaultTabExpansion $line $lastWord }
    }
}

# dotnet completions, see at: https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete#powershell
if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
  # PowerShell parameter completion shim for the dotnet CLI
	Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
		param($wordToComplete, $commandAst, $cursorPosition)
			dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
		}
	}
}
# dotnet script end

if (Get-Command deno -ErrorAction Ignore) {
    Invoke-Expression -Command $(deno completions powershell | Out-String)
}

if (Get-Command carapace -ErrorAction Ignore) {
    $bridges = @()
    if (Get-Command inshellisense -ErrorAction Ignore) {
        $bridges += 'inshellisense'
    }
    if ($IsLinux) {
        $bridges += 'bash'
    }
    if ($bridges) {
        $env:CARAPACE_BRIDGES = $bridges -join ','
    }
    Remove-Variable bridges
    if ($PSEdition -eq 'Core') {
        Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
    }
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    carapace _carapace | Out-String | Invoke-Expression
}
