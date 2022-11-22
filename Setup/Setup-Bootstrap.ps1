$script:runSetup = -1
$script:choices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Install")
    [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not install")
)
function PromptForSetup {
    if ($runSetup -eq -1) {
        $script:runSetup = $Host.UI.PromptForChoice("Missing required components", "Some components (pwsh and/or git) are missing and profile initialization will not work properly. Install them?", $choices, 1)
    }
}

if ($null -eq (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    PromptForSetup
    if ($runSetup -eq 0) {
        winget install --accept-package-agreements --accept-source-agreements Microsoft.PowerShell
    }
}
if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
    PromptForSetup
    if ($runSetup -eq 0) {
        winget install --accept-package-agreements --accept-source-agreements Git.Git
    }
}
if ($runSetup -eq 0) {
    Sync-Path
}
