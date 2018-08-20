$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

if (Get-Command dotnet -ErrorAction Ignore) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

. "$root/Modules/psake/tabexpansion/PsakeTabExpansion.ps1"
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
