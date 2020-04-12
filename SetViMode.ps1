if (Get-Command vim -ErrorAction Ignore) {
    Set-PSReadlineOption -EditMode Vi
    #Set-PSReadlineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
    #Set-PSReadlineKeyHandler -Key Ctrl+Shift+r -Function ForwardSearchHistory
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadlineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
    if (!($env:VISUAL)) {
        $env:VISUAL = "vim"
    }
    if (!($env:GIT_EDITOR)) {
        $vimPath = (Get-Command vim).Path
        $env:GIT_EDITOR = "'$vimPath'"
    }
}
