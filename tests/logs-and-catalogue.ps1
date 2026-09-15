#requires -Version 5.1
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'scripts/common.ps1')
. (Join-Path $root 'scripts/install-packages.ps1')
$c=Import-PowerShellDataFile -LiteralPath (Join-Path $root 'config/packages.psd1')

$fixtures = @(
    @{ Name='authorization bearer header'; Text='Authorization: Bearer fixture_access_value'; Secret='fixture_access_value' },
    @{ Name='standalone bearer'; Text='request failed: Bearer fixture_bearer_value'; Secret='fixture_bearer_value' },
    @{ Name='quoted JSON password'; Text='{"password":"fixture_password_value"}'; Secret='fixture_password_value' },
    @{ Name='plain password'; Text='password=fixture_plain_password'; Secret='fixture_plain_password' },
    @{ Name='GitHub token shape'; Text='token ghp_fixtureToken123'; Secret='ghp_fixtureToken123' },
    @{ Name='JWT shape'; Text='token eyJfixture.header.signature'; Secret='eyJfixture.header.signature' },
    @{ Name='query string'; Text='https://example.test/callback?code=fixture_query_value&state=x'; Secret='fixture_query_value' },
    @{ Name='Korean space user path'; Text='C:\Users\홍 길동\Pictures\sample.jpg'; Secret='홍 길동' }
)
foreach ($fixture in $fixtures) {
    $masked = Protect-Text $fixture.Text
    if ($masked -match [regex]::Escape($fixture.Secret)) { throw ('Secret/path not redacted: ' + $fixture.Name) }
}

$r=New-PackageResult x FAILED INSTALL '' 99 'Authorization: Bearer fixture_json_secret; {"password":"fixture_json_password"}'
$json=ConvertTo-SafeResultsJson @($r)
$parsed=@($json | ConvertFrom-Json)
if ($parsed.Count -ne 1 -or $parsed[0].installerExitCode -ne 99) { throw 'Safe logs must remain valid JSON with typed exit codes.' }
if ($json -match 'fixture_json_secret|fixture_json_password') { throw 'Safe JSON leaked a fixture secret.' }

if (-not (Test-RebootRequiredExitCode 3010)) { throw 'MSI reboot code 3010 must remain supported.' }
if (-not (Test-RebootRequiredExitCode 1641)) { throw 'MSI reboot code 1641 must remain supported.' }
if (-not (Test-RebootRequiredExitCode -1978334966)) { throw 'Signed WinGet reboot HRESULT must be classified.' }
if (-not (Test-RebootRequiredExitCode ([uint32]2316632330))) { throw 'Unsigned WinGet reboot HRESULT must be classified.' }
if (Test-RebootRequiredExitCode 99) { throw 'General failures must not be classified as reboot-required.' }

$n=@($c.Packages | Where-Object { $_.Id -eq 'OpenJS.NodeJS.LTS' })[0]
$arguments=@(Get-InstallArguments $n)
if ($arguments[$arguments.IndexOf('--version')+1] -ne '24.19.0') { throw 'Node manifest pin was not reviewed.' }
if ($arguments[$arguments.IndexOf('--installer-type')+1] -ne 'wix') { throw 'Use full Node MSI, not a portable node-only alias.' }
if (@($c.Packages | Where-Object { $_.Id -eq 'Microsoft.VisualStudioCode' })[0].MinVersion -ne '1.98.0') { throw 'Claude Code minimum VS Code version mismatch.' }
Write-Host ('ADDITIONAL_TESTS_PASS=' + ($fixtures.Count + 10))
