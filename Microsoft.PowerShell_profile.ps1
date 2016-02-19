$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
if (Test-Path "$env:ProgramFiles\Git\usr\bin") { #enable ssh-agent from posh-git
    $env:path="$env:path;$env:ProgramFiles\Git\usr\bin"
}
if (Test-Path "$root\Modules\psake") { #enable ssh-agent from posh-git
    $env:path="$env:path;$root\Modules\psake"
}
. $root\Modules\posh-git\profile.example.ps1
Import-Module z
Import-Module psake

#psake expansion
Push-Location $root
. ./PsakeTabExpansion.ps1
Pop-Location
if((Test-Path Function:\TabExpansion) -and (-not (Test-Path Function:\DefaultTabExpansion))) {
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
#end of psake expansion

function Set-MyAlias($name, $alias) {
    "function global:$name { Invoke-Expression ('$alias ' + (`$args -join ' ')) }" | iex
}

#aliases:
function add {
    if ($args) {
        Invoke-Expression ( "git add " + ($args -join ' ') )
    } else {
        git add -A :/
    }
}
Set-MyAlias st 'git status'
Set-MyAlias push 'git push'
Set-MyAlias pull 'git pull'
Set-MyAlias log 'git log'
Set-MyAlias ci 'git commit'
Set-MyAlias co 'git checkout'
Set-MyAlias dif 'git diff'
Set-MyAlias rs 'git reset'
Set-MyAlias rb 'git rebase'
Set-MyAlias fixup 'git fixup'
Set-MyAlias l 'ls'
Set-MyAlias ll 'ls -Force'

function time() {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Invoke-Expression $($args -join ' ')
    $sw.Stop()
    $sw.elapsed
}