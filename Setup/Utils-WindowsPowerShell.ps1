#Requires -PSEdition Desktop
#Requires -Version 5.1
Set-StrictMode -Version 3.0

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if (!$isDotSourced) {
    Write-Error "This script has to be sourced."
    exit 1
}

$script:profileDir = Join-Path $PSScriptRoot .. Profile
. "$profileDir/Functions.ps1"

function Install-FontWindows {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', "", Scope = 'function', Justification = 'Windows is singular')]
    param
    (
        [System.IO.FileInfo]$fontFile,
        [switch]$DryRun
    )
    if (!(Test-Elevated)) {
        Write-Error "This script must be run as administrator."
        return
    }
    Add-Type -AssemblyName PresentationFramework -PassThru | Out-Null
    $glyph = [System.Windows.Media.GlyphTypeface]::new($fontFile.FullName)
    $family = $glyph.Win32FamilyNames['en-us']
    if ($null -eq $family) { $family = $glyph.Win32FamilyNames.Values.Item(0) }
    $face = $glyph.Win32FaceNames['en-us']
    if ($null -eq $face) { $face = $glyph.Win32FaceNames.Values.Item(0) }
    $fontName = ("$family $face").Trim()

    switch ($fontFile.Extension) {
        ".ttf" { $fontName = "$fontName (TrueType)" }
        ".otf" { $fontName = "$fontName (OpenType)" }
    }

    Write-Host "Installing font: '$fontFile' with font name '$fontName'..."

    If (!(Test-Path ("$env:windir\Fonts\$($fontFile.Name)"))) {
        Write-Host "Copying font: '$fontFile'..."
        if (!$DryRun) {
            Copy-Item -Path $fontFile.FullName -Destination ("$($env:windir)\Fonts\" + $fontFile.Name) -Force
            Write-Host "Copied $fontName."
        }
    } else {
        Write-Host "Font already exists: '$fontFile'"
    }

    If (!(Get-ItemProperty -Name $fontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
        Write-Host "Registering font: '$fontFile'"
        if (!$DryRun) {
            New-ItemProperty -Name $fontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $fontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Host "Registerd $fontName."
        }
    } else {
        Write-Host "Font already registered: '$fontFile'"
    }
}
