[cmdletbinding()] Param()

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

$wslConf = (Join-Path $env:USERPROFILE .wslconfig).Replace('\', '\\')

if (-not (Test-Path $wslConf)) {
    New-Item -ItemType File -Path $wslConf | Out-Null
}

$totalMemory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb
$wslMemory = if ($totalMemory -ge 32) { 16 } else { 8 }
$wslSwap = if ($wslMemory -ge 16) { 4 } else { 1 }

[bool]$isSetup = (python3 -c @"
import configparser
config = configparser.ConfigParser(allow_no_value=True)
config.read('$wslConf')
print(config.has_option('wsl2', 'networkingMode'))
"@) -eq 'True'

if ($isSetup) {
    Write-Verbose "WSL is already configured, revisiting..."
} else {
    Write-Verbose "This is a new WSL configuration..."
}
python3 -c @"
import configparser
config = configparser.ConfigParser(comment_prefixes='/', allow_no_value=True)
config.optionxform = lambda option: option
config.read('$wslConf')

if not config.has_section('wsl2'):
  config.add_section('wsl2')
if not config.has_option('wsl2', 'memory') or config['wsl2']['memory'] != '$($wslMemory)GB':
  config['wsl2']['memory'] = '$($wslMemory)GB'
if not config.has_option('wsl2', 'swap') or config['wsl2']['swap'] != '$($wslSwap)GB':
  config['wsl2']['swap'] = '$($wslSwap)GB'
if not config.has_option('wsl2', 'networkingMode') or config['wsl2']['networkingMode'] != 'mirrored':
  config['wsl2']['networkingMode'] = 'mirrored'
if not config.has_option('wsl2', 'kernelCommandLine') or config['wsl2']['kernelCommandLine'] != 'cgroup_no_v1=all':
  config['wsl2']['kernelCommandLine'] = 'cgroup_no_v1=all'

config.write(open('$wslConf', 'w'))
"@
