if (Test-Path "$env:path;$env:ProgramFiles\Git\usr\bin") { #enable ssh-agent from posh-git
    $env:path="$env:path;$env:ProgramFiles\Git\usr\bin"
}
$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. $root\Modules\posh-git\profile.example.ps1
Import-Module z