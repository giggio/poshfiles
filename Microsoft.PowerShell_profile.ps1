$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
if ((Test-Path "$env:ProgramFiles\Git\usr\bin") -and ($env:path.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0)) { # enable ssh-agent from posh-git
    $env:path="$env:path;$env:ProgramFiles\Git\usr\bin"
}

if ((Test-Path "$root\Modules\psake") -and ($env:path.IndexOf("$($root)\Modules\psake", [StringComparison]::CurrentCultureIgnoreCase) -lt 0)) {
    $env:path="$env:path;$root\Modules\psake"
}
Import-Module "$root\modules\posh-git\src\posh-git.psd1"
Start-SshAgent -Quiet
Import-Module "$root\modules\oh-my-posh\oh-my-posh.psm1" #don't import the psd1, it has an incorrect string in the version field
set-theme Mesh
if (Get-Command colortool -ErrorAction Ignore) { colortool --quiet campbell }
Import-Module z
Import-Module $root\Modules\psake\src\psake.psd1
Import-Module $root\Modules\posh-docker\posh-docker\posh-docker.psd1

Set-PSReadlineOption -TokenKind Command -ForegroundColor Yellow
Set-PSReadlineOption -TokenKind Keyword -ForegroundColor Cyan

. "$root/PsakeTabExpansion.ps1"
. "$root/CreateAliases.ps1"

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    Import-Module "$ChocolateyProfile"
}

if (Get-Command vim -ErrorAction Ignore) {
    Set-PSReadlineOption -EditMode Vi
    Set-PSReadlineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
    Set-PSReadlineKeyHandler -Key Ctrl+Shift+r -Function ForwardSearchHistory
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadlineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
}

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

function pushsync() {
    $branch = $(git rev-parse --abbrev-ref HEAD)
    git push --set-upstream origin $branch
}

if (!(Test-Path "$root\Modules\VSSetup")) {
    Install-Module VSSetup -Scope CurrentUser -Confirm -SkipPublisherCheck
}
