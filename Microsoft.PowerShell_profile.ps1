$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
if (Test-Path "$env:ProgramFiles\Git\usr\bin") { #enable ssh-agent from posh-git
    $env:path="$env:path;$env:ProgramFiles\Git\usr\bin"
}
if (Test-Path "$root\Modules\psake") {
    $env:path="$env:path;$root\Modules\psake"
}
Import-Module "$root\modules\posh-git\src\posh-git.psd1"
Start-SshAgent -Quiet
$env:ConEmuANSI = 'ON' # to fool oh-my-posh and get it to load without conemu
Import-Module "$root\modules\oh-my-posh\oh-my-posh.psm1" #don't import the psd1, it has an incorrect string in the version field
set-theme Mesh
Import-Module z
Import-Module psake
Import-Module $root\Modules\posh-docker\posh-docker\posh-docker.psd1

Set-PSReadlineOption -TokenKind Command -ForegroundColor Yellow
Set-PSReadlineOption -TokenKind Keyword -ForegroundColor Cyan

. "$root/PsakeTabExpansion.ps1"

#aliases:
Set-Alias pester invoke-pester
function add {
    if ($args) {
        Invoke-Expression ( "git add " + ($args -join ' ') )
    } else {
        git add -A :/
    }
}
Add-Alias st 'git status'
Add-Alias push 'git push'
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
Add-Alias l 'ls'
Add-Alias ll 'ls -Force'
Add-Alias gitbash '. "C:\Program Files\Git\usr\bin\bash.exe"'
Add-Alias ccat "pygmentize.exe -g -O style=vs -f console16m"

function time() {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Invoke-Expression $($args -join ' ')
    $sw.Stop()
    $sw.elapsed
}
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
Set-PSReadlineOption -EditMode Vi

#log history
$historyFilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) .ps_history
if (Test-Path $historyFilePath) {
    $numberOfPreviousCommands = $(Get-Content $historyFilePath | Measure-Object -Line).Lines - 1
} else {
    $numberOfPreviousCommands = 1
}
Register-EngineEvent PowerShell.Exiting -Action {
    $history = Get-History
    $filteredHistory = $history[($numberOfPreviousCommands-1)..($history.Length - 2)]
    $filteredHistory | Export-Csv $historyFilePath -Append
} | Out-Null
if (Test-path $historyFilePath) { Import-Csv $historyFilePath | Add-History }

if (gcm hub -ErrorAction SilentlyContinue) {
    Add-Alias git "$($(gcm hub).Source)"
}

function color ($lexer='javascript') {
    Begin { $t = "" }
    Process { $t = "$t
    $_" }
    End { $t | pygmentize.exe -l $lexer -O style=vs -f console16m; }
} # call like: docker inspect foo | color