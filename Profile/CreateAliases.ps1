Set-Alias pester invoke-pester
Set-Alias psake invoke-psake
Set-Alias k kubectl
function add {
    if ($args) {
        Invoke-Expression ( "git add " + ($args -join ' ') )
    } else {
        git add -A :/
    }
}
if (Get-Command Add-Alias -ErrorAction Ignore) {
    Add-Alias st 'git status'
    Add-Alias push 'git push'
    Add-Alias pushf 'git push -f'
    Add-Alias pull 'git pull'
    Add-Alias log 'git log'
    Add-Alias ci 'git commit'
    Add-Alias co 'git checkout'
    Add-Alias dif 'git diff'
    Add-Alias rs 'git reset'
    Add-Alias rb 'git rebase'
    Add-Alias fixup 'git fixup'
    Add-Alias branch 'git branch'
    Add-Alias tag 'git tag'
    Add-Alias up 'git up'
    Add-Alias sync 'git sync'
    if ($lsApp = Get-Command ls -CommandType Application -ErrorAction Ignore) {
        Add-Alias ll "$($lsApp.Source) -la"
        Remove-Variable lsApp
    } else {
        Add-Alias ll 'ls -Force'
    }
}
Set-Alias l 'ls'
if (Get-Command hub -ErrorAction Ignore) {
    Set-Alias git "$($(Get-Command hub).Source)"
}
if (Get-Command curl -CommandType Application -ErrorAction Ignore) {
    #use system curl if available
    if (Get-Alias curl -ErrorAction Ignore) {
        Remove-Item alias:curl
    }
}

function pushsync() {
    $branch = $(git rev-parse --abbrev-ref HEAD)
    git push --set-upstream origin $branch
}
