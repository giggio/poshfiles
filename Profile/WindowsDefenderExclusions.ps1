function Add-WindowsDefenderExclusions {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    param (
        [switch] $DryRun
    )
    if (!(Test-Elevated)) {
        Write-Error "Cannot add exclusions, needs to be elevated."
    }
    $projectsDir = (Get-Item $PSScriptRoot).Parent.Parent.FullName
    $pathExclusions = New-Object System.Collections.ArrayList
    $processExclusions = New-Object System.Collections.ArrayList

    $pathExclusions.Add($projectsDir) | Out-Null
    $pathExclusions.Add("$env:windir\Microsoft.NET") | Out-Null
    $pathExclusions.Add("$env:windir\assembly") | Out-Null
    $pathExclusions.Add("$home\.dotnet") | Out-Null
    $pathExclusions.Add("$home\.librarymanager") | Out-Null
    $pathExclusions.Add("$env:LOCALAPPDATA\Microsoft\VisualStudio") | Out-Null
    $pathExclusions.Add("$env:LOCALAPPDATA\Microsoft\VisualStudio Services") | Out-Null
    $pathExclusions.Add("$env:LOCALAPPDATA\GitCredentialManager") | Out-Null
    $pathExclusions.Add("$env:LOCALAPPDATA\GitHubVisualStudio") | Out-Null
    $pathExclusions.Add("$env:LOCALAPPDATA\Microsoft\dotnet") | Out-Null
    $pathExclusions.Add("$env:LOCALAPPDATA\Microsoft\VSApplicationInsights") | Out-Null
    $pathExclusions.Add("$env:LOCALAPPDATA\Microsoft\VSCommon") | Out-Null
    $pathExclusions.Add("$env:LOCALAPPDATA\Temp\VSFeedbackIntelliCodeLogs") | Out-Null
    $pathExclusions.Add("$env:APPDATA\Microsoft\VisualStudio") | Out-Null
    $pathExclusions.Add("$env:APPDATA\NuGet") | Out-Null
    $pathExclusions.Add("$env:APPDATA\Visual Studio Setup") | Out-Null
    $pathExclusions.Add("$env:APPDATA\vstelemetry") | Out-Null
    $pathExclusions.Add("$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine") | Out-Null
    $pathExclusions.Add("$env:ProgramData\Microsoft\VisualStudio") | Out-Null
    $pathExclusions.Add("$env:ProgramData\Microsoft\NetFramework") | Out-Null
    $pathExclusions.Add("$env:ProgramData\Microsoft Visual Studio") | Out-Null
    $pathExclusions.Add("$env:ProgramData\MySQL") | Out-Null
    $pathExclusions.Add("$env:ProgramFiles\Microsoft Visual Studio") | Out-Null
    $pathExclusions.Add("$env:ProgramFiles\dotnet") | Out-Null
    $pathExclusions.Add("$env:ProgramFiles\Microsoft SDKs") | Out-Null
    $pathExclusions.Add("$env:ProgramFiles\Microsoft SQL Server") | Out-Null
    $pathExclusions.Add("$env:ProgramFiles\MySQL") | Out-Null
    $pathExclusions.Add("$env:ProgramFiles\IIS") | Out-Null
    $pathExclusions.Add("$env:ProgramFiles\IIS Express") | Out-Null
    $pathExclusions.Add("${env:ProgramFiles(x86)}\Microsoft Visual Studio") | Out-Null
    $pathExclusions.Add("${env:ProgramFiles(x86)}\dotnet") | Out-Null
    $pathExclusions.Add("${env:ProgramFiles(x86)}\Microsoft SDKs") | Out-Null
    $pathExclusions.Add("${env:ProgramFiles(x86)}\Microsoft SQL Server") | Out-Null
    $pathExclusions.Add("${env:ProgramFiles(x86)}\IIS") | Out-Null
    $pathExclusions.Add("${env:ProgramFiles(x86)}\IIS Express") | Out-Null

    $processExclusions.Add("Microsoft.ServiceHub.Controller.exe") | Out-Null
    $processExclusions.Add("ServiceHub.DataWarehouseHost.exe") | Out-Null
    $processExclusions.Add("ServiceHub.Host.CLR.exe") | Out-Null
    $processExclusions.Add("ServiceHub.Host.CLR.x64.exe") | Out-Null
    $processExclusions.Add("ServiceHub.Host.CLR.x86.exe") | Out-Null
    $processExclusions.Add("ServiceHub.Host.Node.x86.exe") | Out-Null
    $processExclusions.Add("ServiceHub.IdentityHost.exe") | Out-Null
    $processExclusions.Add("ServiceHub.IndexingService.exe") | Out-Null
    $processExclusions.Add("ServiceHub.RoslynCodeAnalysisService.exe") | Out-Null
    $processExclusions.Add("ServiceHub.SettingsHost.exe") | Out-Null
    $processExclusions.Add("ServiceHub.TestWindowStoreHost.exe") | Out-Null
    $processExclusions.Add("ServiceHub.ThreadedWaitDialog.exe") | Out-Null
    $processExclusions.Add("ServiceHub.VSDetouredHost.exe") | Out-Null
    $processExclusions.Add("vstest.console.exe") | Out-Null
    $processExclusions.Add("Microsoft.VisualStudio.Web.Host.exe") | Out-Null
    $processExclusions.Add("Microsoft.WebTools.Languages.LanguageServer.Host.exe") | Out-Null
    $processExclusions.Add("node.exe") | Out-Null
    $processExclusions.Add("deno.exe") | Out-Null
    $processExclusions.Add("PerfWatson2.exe") | Out-Null
    $processExclusions.Add("sqlwriter.exe") | Out-Null
    $processExclusions.Add("sqlservr.exe") | Out-Null
    $processExclusions.Add("com.docker.service.exe") | Out-Null
    $processExclusions.Add("dotnet.exe") | Out-Null
    $processExclusions.Add("Code.exe") | Out-Null
    $processExclusions.Add("gpg-agent.exe") | Out-Null
    $processExclusions.Add("ssh-agent.exe") | Out-Null
    $processExclusions.Add("vsls-agent.exe") | Out-Null
    $processExclusions.Add("iisexpress.exe") | Out-Null
    $processExclusions.Add("nvm.exe") | Out-Null
    $processExclusions.Add("wsl.exe") | Out-Null

    Write-Output "Adding exclusions to Windows Defender$(if ($DryRun) { " (dry run)." } else { "." })"

    $prefs = Get-MpPreference
    $exclusionPaths = $prefs.ExclusionPath | Sort-Object
    $exclusionProcesses = $prefs.ExclusionProcess | Sort-Object
    $newExclusionPaths = $pathExclusions | Where-Object { $exclusionPaths -notcontains $_ }
    $newExclusionProcesses = $processExclusions | Where-Object { $exclusionProcesses -notcontains $_ }

    if ($newExclusionPaths.Count) {
        foreach ($pathExclusion in $newExclusionPaths) {
            Write-Output "Adding Path Exclusion: $pathExclusion"
            if (!$DryRun) {
                Add-MpPreference -ExclusionPath $pathExclusion
            }
        }
    } else {
        Write-Host "No Path exclusions to add."
    }

    if ($newExclusionProcesses.Count) {
        foreach ($processExclusion in $newExclusionProcesses) {
            Write-Output "Adding Process Exclusion: $processExclusion"
            if (!$DryRun) {
                Add-MpPreference -ExclusionProcess $processExclusion
            }
        }
    } else {
        Write-Host "No Process exclusions to add."
    }

    if ($PSCmdlet.MyInvocation.BoundParameters.Verbose) {
        Get-WindowsDefenderExclusions -Verbose
    }
}

function Get-WindowsDefenderExclusions {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    param ()
    if (!(Test-Elevated)) {
        Write-Error "Cannot get exclusions, needs to be elevated."
    }

    $prefs = Get-MpPreference
    $exclusionPaths = $prefs.ExclusionPath | Sort-Object
    $exclusionProcesses = $prefs.ExclusionProcess | Sort-Object

    function Write-Exact($text) {
        if ($PSCmdlet.MyInvocation.BoundParameters.Verbose) {
            Write-Verbose $text
        } else {
            Write-Host $text
        }

    }
    Write-Exact "Your Exclusions:"
    Write-Exact "Paths:"
    foreach ($e in $exclusionPaths) { Write-Exact "$e" }
    Write-Exact "`nProcesses:"
    foreach ($e in $exclusionProcesses) { Write-Exact "$e" }
}
