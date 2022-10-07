$localModulesDirectory = Resolve-Path (Join-Path (Join-Path $PSScriptRoot ..) Modules)

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

# dotnet completions, see more at https://learn.microsoft.com/dotnet/core/tools/enable-tab-autocomplete#powershell
if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

if (Get-Command dotnet -ErrorAction Ignore) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

if (Get-Command deno -ErrorAction Ignore) {
    Invoke-Expression -Command $(deno completions powershell | Out-String)
}
