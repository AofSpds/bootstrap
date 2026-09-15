#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Plan','Install','Verify')][string]$Mode='Plan',
    [ValidateSet('Core')][string]$Profile='Core',
    [ValidateSet('None','Codex','Claude','Both')][string]$AI='None',
    [ValidateSet('Python','JDK','Docker','DBeaver')][string[]]$Optional=@(),
    [switch]$AcceptAgreements,
    [switch]$NonInteractive
)
$ErrorActionPreference='Stop'
foreach ($script in @('common','preflight','verify','install-packages','install-ai')) { . (Join-Path $PSScriptRoot ('scripts/' + $script + '.ps1')) }
try {
    $catalogue = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot 'config/packages.psd1')
    if ($Mode -eq 'Install' -and $NonInteractive -and (-not $AcceptAgreements -or -not $PSBoundParameters.ContainsKey('AI') -or -not $PSBoundParameters.ContainsKey('Profile'))) {
        Write-Host '[ACTION_REQUIRED] NonInteractive requires explicit -Profile Core -AI ... -AcceptAgreements. Omitted Optional means none.'
        exit 2
    }
    if ($Mode -eq 'Install' -and -not $NonInteractive) {
        if (-not $PSBoundParameters.ContainsKey('AI')) {
            Write-Host 'AI: 0=None 1=Codex(ChatGPT) 2=Claude 3=Both. No account/payment is created.'
            $choice = Read-Host 'Choose [0]'
            switch ($choice) { '1' {$AI='Codex'} '2' {$AI='Claude'} '3' {$AI='Both'} '0' {$AI='None'} '' {$AI='None'} default {Write-Host '[ACTION_REQUIRED] Invalid choice; nothing installed.'; exit 2} }
        }
        if (-not $PSBoundParameters.ContainsKey('Optional')) {
            $extra = Read-Host 'Optional: Python,JDK,Docker,DBeaver (comma separated; Enter=none)'
            if ($extra.Trim()) {
                $Optional = @($extra.Split(',') | ForEach-Object { $_.Trim() } | Select-Object -Unique)
                foreach ($item in $Optional) { if ($item -notin @('Python','JDK','Docker','DBeaver')) { Write-Host '[ACTION_REQUIRED] Unknown optional package; nothing installed.'; exit 2 } }
            }
        }
    }
    $selected = @($catalogue.Packages | Where-Object { $_.Group -eq 'Core' -or $_.Group -in $Optional })
    Write-Host ('BOOTSTRAP v0.1 / Mode=' + $Mode + ' / AI=' + $AI)
    Write-Host ('Selected: ' + (($selected | ForEach-Object { $_.Name }) -join ', '))
    Write-Host 'Existing apps are preserved. No automatic upgrade, reboot, login, payment or WSL enablement.'
    if ('Docker' -in $Optional) { Write-Host 'Docker Desktop has license conditions. Review https://docs.docker.com/subscription/desktop-license/ before consenting.' }
    $issues = @(Test-Preflight $Mode)
    foreach ($issue in $issues) { Write-Host ('[ACTION_REQUIRED] ' + $issue) }
    if ($issues.Count -gt 0 -and $Mode -ne 'Plan') { exit 2 }
    if ($env:OS -ne 'Windows_NT') { exit 2 }
    if ($Mode -eq 'Install' -and -not $AcceptAgreements) {
        $answer = Read-Host 'Install the selected software and accept its source/package terms? [y/N]'
        if ($answer -notin @('y','yes')) { Write-Host '[SKIP] Cancelled. Nothing installed.'; exit 2 }
    }
    $results = @()
    foreach ($package in $selected) {
        try { $result = Invoke-PackageStep $package $Mode }
        catch { $result = New-PackageResult $package.Id 'FAILED' $Mode '' $null (Protect-Text $_.Exception.Message) }
        $results += $result
        Write-Host ('[' + $result.status + '] ' + $package.Name + ' ' + $result.detectedVersion + ' ' + $result.nextAction)
    }
    $results += @(Invoke-AISteps $AI $Mode $catalogue)
    $results | Format-Table packageId,status,detectedVersion,action -AutoSize | Out-Host
    if ($Mode -eq 'Install') { Save-SafeResults $results }
    Write-Host 'Next: GitHub Desktop sign-in -> clone YOUR app -> Open in VS Code -> sign in to the selected AI.'
    Write-Host 'Details: docs/FIRST_RUN.md and docs/TROUBLESHOOTING.md (Korean).'
    if ($issues.Count -gt 0) { exit 2 }
    exit (Get-OverallExitCode $results)
} catch {
    Write-Host ('[ERROR] ' + (Protect-Text $_.Exception.Message))
    Write-Host 'No automatic rollback/removal was attempted. Keep this summary and consult docs/TROUBLESHOOTING.md.'
    exit 1
}
