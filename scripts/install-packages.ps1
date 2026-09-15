function Get-InstallArguments {
    param([hashtable]$Package)
    $args = @('install','--id',$Package.Id,'--exact','--source','winget','--no-upgrade','--silent','--disable-interactivity','--accept-source-agreements','--accept-package-agreements')
    if ($Package['Scope']) { $args += @('--scope',$Package['Scope']) }
    if ($Package['InstallerType']) { $args += @('--installer-type',$Package['InstallerType']) }
    if ($Package['PinnedVersion']) { $args += @('--version',$Package['PinnedVersion']) }
    if ($Package['RequiresVirtualization']) { $args += '--skip-dependencies' }
    return $args
}

function Invoke-PackageStep {
    param([hashtable]$Package, [ValidateSet('Plan','Install','Verify')][string]$Mode)
    $state = Get-PackageState $Package
    $requested = [string]$Package['PinnedVersion']
    if ($state.Present -and $state.Compatible) { return New-PackageResult $Package.Id 'PRESENT_COMPATIBLE' 'SKIP' $state.Version $null '' $requested }
    if ($state.Present) { return New-PackageResult $Package.Id 'ACTION_REQUIRED' 'KEEP_EXISTING' $state.Version $null ('Existing version is unsupported or incomplete. ' + $state.Detail) $requested }
    if ($Mode -eq 'Plan') { return New-PackageResult $Package.Id 'SKIPPED' 'WOULD_INSTALL' '' $null 'Run Install after reviewing the plan.' $requested }
    if ($Mode -eq 'Verify') { return New-PackageResult $Package.Id 'ACTION_REQUIRED' 'MISSING' '' $null 'Run Install to add this package.' $requested }
    if ($Package['RequiresVirtualization'] -and -not (Test-DockerPrerequisites)) { return New-PackageResult $Package.Id 'ACTION_REQUIRED' 'PREREQUISITE' '' $null 'Docker requires existing WSL/virtualization and license acceptance. No Windows features were enabled.' $requested }
    $winget = Get-Command winget.exe -CommandType Application -ErrorAction Stop
    Write-Host ('[INSTALLING] ' + $Package.Name)
    $run = Invoke-Native $winget.Source (Get-InstallArguments $Package)
    if ($run.ExitCode -in @(3010,1641)) { return New-PackageResult $Package.Id 'REBOOT_REQUIRED' 'INSTALL' '' $run.ExitCode 'Restart manually when convenient, then Verify.' $requested }
    Update-ProcessPath
    $after = Get-PackageState $Package
    if ($run.ExitCode -eq 0 -and $after.Present -and $after.Compatible) { return New-PackageResult $Package.Id 'INSTALLED' 'INSTALL' $after.Version $run.ExitCode '' $requested }
    $detail = Protect-Text (($run.Output -split "`n" | Select-Object -Last 6) -join ' ')
    return New-PackageResult $Package.Id 'FAILED' 'INSTALL' $after.Version $run.ExitCode ('Installer or post-install check failed. Run Verify/retry; existing software is preserved. ' + $detail) $requested
}
