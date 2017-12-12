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
if (Get-Command colortool -ErrorAction Ignore) { colortool --quiet campbell }
Import-Module z
Import-Module psake
Import-Module $root\Modules\posh-docker\posh-docker\posh-docker.psd1

Set-PSReadlineOption -TokenKind Command -ForegroundColor Yellow
Set-PSReadlineOption -TokenKind Keyword -ForegroundColor Cyan

. "$root/PsakeTabExpansion.ps1"
. "$root/CreateAliases.ps1"

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    Import-Module "$ChocolateyProfile"
}

Set-PSReadlineOption -EditMode Vi
Set-PSReadlineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
Set-PSReadlineKeyHandler -Key Ctrl+Shift+r -Function ForwardSearchHistory

function time() {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Invoke-Expression $($args -join ' ')
    $sw.Stop()
    $sw.elapsed
} # call like: `time ls` or `time git log`

function color ($lexer='javascript') {
    Begin { $t = "" }
    Process { $t = "$t
    $_" }
    End { $t | pygmentize.exe -l $lexer -O style=vs -f console16m; }
} # call like: `docker inspect foo | color`

if (Get-Command dotnet -ErrorAction Ignore) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}
