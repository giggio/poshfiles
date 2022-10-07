Set-Alias gitbash "$env:ProgramFiles\Git\usr\bin\bash.exe"
if (Get-Command Add-Alias -ErrorAction Ignore) {
    Add-Alias ll 'ls -Force'
}
