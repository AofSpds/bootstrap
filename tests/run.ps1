#requires -Version 5.1
$ErrorActionPreference='Stop'
$root = Split-Path -Parent $PSScriptRoot
foreach ($name in @('common','preflight','verify','install-packages','install-ai')) { . (Join-Path $root ('scripts/' + $name + '.ps1')) }
$script:count=0
function Assert-True { param([bool]$Condition,[string]$Name); if (-not $Condition) { throw ('FAIL: ' + $Name) }; $script:count++; Write-Host ('PASS: ' + $Name) }
$files = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object { $_.Extension -in @('.ps1','.psd1') })
foreach ($file in $files) {
    $tokens=$null; $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
    Assert-True ($errors.Count -eq 0) ('parser: ' + $file.Name)
}
$c = Import-PowerShellDataFile -LiteralPath (Join-Path $root 'config/packages.psd1')
Assert-True (@($c.Packages | Where-Object { $_.Group -eq 'Core' }).Count -eq 8) 'eight core packages'
Assert-True (@($c.Packages.Id | Select-Object -Unique).Count -eq $c.Packages.Count) 'unique package IDs'
Assert-True (@(Get-AIExtensionIds None $c).Count -eq 0) 'AI None is empty'
Assert-True (@(Get-AIExtensionIds Both $c).Count -eq 2) 'AI Both has two official extensions'
Assert-True ((Get-AIExtensionIds Codex $c) -eq 'openai.chatgpt') 'Codex exact ID'
Assert-True ((Get-AIExtensionIds Claude $c) -eq 'anthropic.claude-code') 'Claude exact ID'
$n = @($c.Packages | Where-Object { $_.Id -eq 'OpenJS.NodeJS.LTS' })[0]
Assert-True (Test-CompatibleVersion $n '24.21.0') 'supported Node 24'
Assert-True (Test-CompatibleVersion $n '22.23.2') 'supported Node 22'
Assert-True (-not (Test-CompatibleVersion $n '20.19.0')) 'old Node rejected'
Assert-True (-not (Test-CompatibleVersion $n '25.1.0')) 'non-LTS major rejected'
Assert-True (-not (Test-CompatibleVersion $n 'unknown')) 'unknown version rejected'
$args = @(Get-InstallArguments $n)
Assert-True ('--no-upgrade' -in $args) 'no upgrade'
Assert-True ('--allow-reboot' -notin $args) 'no reboot'
Assert-True ('--force' -notin $args -and '--ignore-security-hash' -notin $args) 'no force/hash bypass'
Assert-True ($args[$args.IndexOf('--source')+1] -eq 'winget') 'fixed source'
Assert-True ((Protect-Text 'Authorization: Bearer fixture_access_value access_token=fixture_refresh_value https://example.test/a?signature=fixture_query_value') -notmatch 'fixture_access_value|fixture_refresh_value|fixture_query_value') 'safe log redaction'
Assert-True ((Protect-Text 'C:\Users\홍 길동\Pictures') -notmatch '홍 길동') 'user path redaction'
Assert-True ((Get-OverallExitCode @((New-PackageResult x 'PRESENT_COMPATIBLE' SKIP))) -eq 0) 'success exit'
Assert-True ((Get-OverallExitCode @((New-PackageResult x FAILED INSTALL))) -eq 1) 'failure exit'
Assert-True ((Get-OverallExitCode @((New-PackageResult x REBOOT_REQUIRED INSTALL))) -eq 2) 'reboot requires owner'
Assert-True (Test-RebootRequiredExitCode -1978334966) 'signed WinGet reboot HRESULT'
Assert-True (Test-RebootRequiredExitCode ([uint32]2316632330)) 'unsigned WinGet reboot HRESULT'
Assert-True (-not (Test-RebootRequiredExitCode 99)) 'general failure is not reboot-required'

# Unit fixtures override OS/native boundaries. They never call an installer.
$script:present=$true; $script:compatible=$true; $script:calls=0; $script:nativeCode=0; $script:appear=$true
function Get-PackageState { param($Package); [pscustomobject]@{Present=$script:present; Compatible=$script:compatible; Version='24.21.0'; Detail='fixture'} }
function Get-Command { param($Name,$CommandType,$ErrorAction); [pscustomobject]@{Source='fixture-winget'} }
function Invoke-Native { param($FilePath,$Arguments); $script:calls++; if($script:appear){$script:present=$true;$script:compatible=$true}; [pscustomobject]@{ExitCode=$script:nativeCode;Output='fixture'} }
function Update-ProcessPath { }
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'PRESENT_COMPATIBLE' -and $script:calls -eq 0) 'installed => no mutation'
$script:compatible=$false
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'ACTION_REQUIRED' -and $script:calls -eq 0) 'incompatible => keep existing'
$script:present=$false
$r = Invoke-PackageStep $n Plan
Assert-True ($r.action -eq 'WOULD_INSTALL' -and $script:calls -eq 0) 'Plan => no mutation'
$r = Invoke-PackageStep $n Verify
Assert-True ($r.status -eq 'ACTION_REQUIRED' -and $script:calls -eq 0) 'Verify => no mutation'
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'INSTALLED' -and $script:calls -eq 1) 'install + post-detection'
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'PRESENT_COMPATIBLE' -and $script:calls -eq 1) 'second run is idempotent'
$script:present=$false; $script:appear=$false
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'FAILED' -and $r.installerExitCode -eq 0) 'exit zero without install is failure'
$script:nativeCode=99
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'FAILED' -and $r.installerExitCode -eq 99) 'raw installer failure preserved'
$script:appear=$true; $script:nativeCode=0
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'INSTALLED') 'retry after failure succeeds'
$script:present=$false; $script:nativeCode=3010
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'REBOOT_REQUIRED') 'reboot is not initiated by bootstrap'
$script:nativeCode=-1978334966
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'REBOOT_REQUIRED' -and $r.installerExitCode -eq -1978334966) 'WinGet signed reboot HRESULT => owner action'
$script:nativeCode=[uint32]2316632330
$r = Invoke-PackageStep $n Install
Assert-True ($r.status -eq 'REBOOT_REQUIRED' -and (ConvertTo-UnsignedWin32ExitCode $r.installerExitCode) -eq 2316632330) 'WinGet unsigned reboot HRESULT => owner action'
Write-Host ('TOTAL_PASS=' + $script:count)
