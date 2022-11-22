#Requires -PSEdition Desktop
#Requires -Version 5.1
Set-StrictMode -Version 3.0

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    Write-Error "This script has to be sourced."
    exit 1
}

$script:profileDir = Join-Path (Join-Path $PSScriptRoot ..) Profile
. "$profileDir/Functions.ps1"

function Install-FontWindows {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', "", Scope = 'function', Justification = 'Windows is singular')]
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'file')][System.IO.FileInfo]$FontFile,
        [Parameter(Mandatory = $true, ParameterSetName = 'url')][uri]$Url,
        [switch]$ForceRegister,
        [Parameter(ParameterSetName = 'url')][switch]$ForceDownload,
        [Parameter(ParameterSetName = 'file')][switch]$ForceCopy
    )
    if (!(Test-Elevated)) {
        Write-Error "This script must be run as administrator."
        return
    }
    if ($PSCmdlet.ParameterSetName -eq 'url') {
        $FontFile = Join-Path $env:TEMP ([System.IO.Path]::GetFileName($Url))
    }
    if ($PSCmdlet.ParameterSetName -eq 'file') {
        if (!(Test-Path $FontFile)) {
            Write-Error "Font file '$FontFile' does not exist."
            return
        }
    }

    $windowsFontPath = "$($env:windir)\Fonts\$($FontFile.Name)"
    If ((Test-Path $windowsFontPath) -and !($ForceDownload -or $ForceCopy)) {
        Write-Host "Font already exists: '$windowsFontPath'"
        if ($ForceRegister) {
            if ($PSCmdlet.ShouldProcess($FontFile.Name, "Register font")) {
                Register-Font $windowsFontPath -ForceRegister
            }
        }
    } else {
        if (!(Test-Path $FontFile) -or $ForceDownload) {
            Write-Verbose "Downloading font from $Url"
            if ($PSCmdlet.ShouldProcess($Url, "Download font")) {
                Invoke-WebRequest -Uri $Url -OutFile $FontFile
            }
        }
        Write-Host "Copying font: '$FontFile'..."
        if ($PSCmdlet.ShouldProcess($FontFile.Name, "Copying font")) {
            Copy-Item -Path $FontFile.FullName -Destination "$windowsFontPath" -Force
            Write-Host "Copied $windowsFontPath."
        }
        if ($PSCmdlet.ShouldProcess($FontFile.Name, "Register font")) {
            Register-Font $FontFile -ForceRegister:$ForceRegister
        }
    }
}

function Register-Font {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)][System.IO.FileInfo]$FontFile,
        [switch]$ForceRegister
    )
    $fontName = Get-FontName $FontFile

    If (!$ForceRegister -and (Get-ItemProperty -Name $fontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
        Write-Host "Font already registered: '$FontFile'"
    } else {
        Write-Host "Registering font: '$FontFile' with font name '$fontName'..."
        if ($PSCmdlet.ShouldProcess($FontFile.Name, 'Registering font')) {
            New-ItemProperty -Name $fontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Host "Registered $fontName."
        }
    }
}

function Get-FontName {
    param
    (
        [Parameter(Mandatory = $true)][System.IO.FileInfo]$FontFile
    )
    $deleteTempFont = $false
    $tempFontPath = "$env:TEMP\$([guid]::NewGuid())$($FontFile.Extension)"
    if ($FontFile -like "$env:windir*" -and $FontFile.Name.Contains(' ')) {
        # Can't create a glyph for a font in the Windows directory with a space in the name
        Copy-Item $FontFile $tempFontPath
        $deleteTempFont = $true
        $FontFile = $tempFontPath
    }
    Add-Type -AssemblyName PresentationFramework -PassThru | Out-Null
    $glyph = [System.Windows.Media.GlyphTypeface]::new($FontFile.FullName)
    $family = $glyph.Win32FamilyNames['en-us']
    if ($null -eq $family) { $family = $glyph.Win32FamilyNames.Values.Item(0) }
    $face = $glyph.Win32FaceNames['en-us']
    if ($null -eq $face) { $face = $glyph.Win32FaceNames.Values.Item(0) }
    $fontName = ("$family $face").Trim()

    switch ($FontFile.Extension) {
        ".ttf" { $fontName = "$fontName (TrueType)" }
        ".otf" { $fontName = "$fontName (OpenType)" }
    }
    if ($deleteTempFont) {
        Remove-Item $tempFontPath
    }
    return $fontName
}
