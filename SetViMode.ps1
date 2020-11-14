if (Get-Module PSReadLine) {
    if (Get-Command vim -ErrorAction Ignore) {
        Set-PSReadLineOption -EditMode Vi
        #Set-PSReadlineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
        #Set-PSReadlineKeyHandler -Key Ctrl+Shift+r -Function ForwardSearchHistory
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
        if (!($env:VISUAL)) {
            $env:VISUAL = "vim"
        }
        if (!($env:GIT_EDITOR)) {
            $vimPath = (Get-Command vim).Path
            $env:GIT_EDITOR = "'$vimPath'"
        }
    }
}
