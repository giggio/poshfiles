if (Get-Module PSReadLine) {
    $vimCommand = Get-Command vim -ErrorAction Ignore
    if ($vimCommand) {
        if (Get-Module PSFzf) {
            Write-Warning "PSFzf is already loaded. Setting Vim keybindings will override PSFzf keybinds (like Ctrl+r)."
        }
        Set-PSReadLineOption -EditMode Vi
        #Set-PSReadlineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
        #Set-PSReadlineKeyHandler -Key Ctrl+Shift+r -Function ForwardSearchHistory
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
        if (!($env:VISUAL)) {
            $env:VISUAL = "vim"
        }
        if (!($env:GIT_EDITOR)) {
            $env:GIT_EDITOR = "'$($vimCommand.Path)'"
        }
    }
    Remove-Variable vimCommand
}
