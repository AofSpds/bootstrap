#requires -Version 5.1
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'scripts/common.ps1')
. (Join-Path $root 'scripts/install-packages.ps1')
$c=Import-PowerShellDataFile -LiteralPath (Join-Path $root 'config/packages.psd1')
$r=New-PackageResult x FAILED INSTALL '' 99 'Authorization=fixture_secret'
$json=ConvertTo-SafeResultsJson @($r)
$parsed=@($json | ConvertFrom-Json)
if ($parsed.Count -ne 1 -or $parsed[0].installerExitCode -ne 99) { throw 'Safe logs must remain valid JSON with typed exit codes.' }
if ($json -match 'fixture_secret') { throw 'Secret not redacted.' }
$n=@($c.Packages | Where-Object { $_.Id -eq 'OpenJS.NodeJS.LTS' })[0]
$arguments=@(Get-InstallArguments $n)
if ($arguments[$arguments.IndexOf('--version')+1] -ne '24.19.0') { throw 'Node manifest pin was not reviewed.' }
if ($arguments[$arguments.IndexOf('--installer-type')+1] -ne 'wix') { throw 'Use full Node MSI, not a portable node-only alias.' }
if (@($c.Packages | Where-Object { $_.Id -eq 'Microsoft.VisualStudioCode' })[0].MinVersion -ne '1.98.0') { throw 'Claude Code minimum VS Code version mismatch.' }
Write-Host 'ADDITIONAL_TESTS_PASS=5'
