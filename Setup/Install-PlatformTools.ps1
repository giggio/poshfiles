#Requires -PSEdition Core
#Requires -Version 7.2
Set-StrictMode -Version 3.0

$script:isDotSourced = $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq ''
if ($isDotSourced) {
    Write-Error "This script must not be sourced."
    return
}

if (Test-Elevated) {
    Write-Error "This script must not be run as administrator."
    exit 1
}

if (!($IsWindows)) {
    Write-Error "This script must be run on Windows."
    exit 1
}

if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    $dotnetTools = @{
        "dotnet-aspnet-codegenerator" = "dotnet-aspnet-codegenerator";
        "dotnet-counters"             = "dotnet-counters";
        "dotnet-delice"               = "dotnet-delice";
        "dotnet-dump"                 = "dotnet-dump";
        "dotnet-gcdump"               = "dotnet-gcdump";
        "dotnet-interactive"          = "Microsoft.dotnet-interactive";
        "dotnet-script"               = "dotnet-script";
        "dotnet-sos"                  = "dotnet-sos";
        "dotnet-suggest"              = "dotnet-suggest";
        "dotnet-trace"                = "dotnet-trace";
        "dotnet-try"                  = "microsoft.dotnet-try";
        "git-istage"                  = "git-istage";
        httprepl                      = "Microsoft.dotnet-httprepl";
        nukeeper                      = "nukeeper";
        pwsh                          = "PowerShell";
    }

    $dotnetToolsDir = "$env:USERPROFILE/.dotnet/tools"
    foreach ($dotnetTool in $dotnetTools.Keys) {
        if (!(Test-Path "$dotnetToolsDir/$dotnetTool.exe")) {
            Write-Host "Install .NET tool $dotnetTool ($($dotnetTools[$dotnetTool]))."
            dotnet tool update --global $dotnetTools[$dotnetTool]
        } else {
            Write-Host ".NET tool $dotnetTool ($($dotnetTools[$dotnetTool])) is already installed."
        }
    }
    if (!(Test-Path "$dotnetToolsDir/tye.exe")) {
        Write-Host "Install Tye."
        dotnet tool update --global Microsoft.Tye --prerelease
    }
    if (!(Test-Path "$dotnetToolsDir/dotnet-symbol.exe") -or !(Test-Path "$HOME/.dotnet/sos")) {
        Write-Host "Install .NET Symbol."
        dotnet tool update --global dotnet-symbol
        & "$env:USERPROFILE/.dotnet/tools/dotnet-sos" install
    }
}
