function Test-Preflight {
    param([ValidateSet('Plan','Install','Verify')][string]$Mode)
    $issues = @()
    if ($env:OS -ne 'Windows_NT') { return @('Supported target: Windows 11 x64. No installation was attempted.') }
    if (-not [Environment]::Is64BitProcess) { $issues += 'Open 64-bit Windows PowerShell, not the x86 shell.' }
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -ne 'AMD64') { $issues += 'ARM64 and other architectures are not validated by this candidate.' }
    if ([Environment]::OSVersion.Version.Build -lt 22000) { $issues += 'Windows 11 is the tested target. Older systems require separate validation.' }
    try {
        $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        if ($computer.PartOfDomain) { $issues += 'Domain-managed PC: obtain administrator approval; automatic install is blocked.' }
    } catch { $issues += 'Could not check device management. Ask the PC administrator before installing.' }
    if ($Mode -eq 'Verify') { return $issues }
    $winget = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue
    if (-not $winget) { $issues += 'WinGet is missing. Install/repair Microsoft App Installer using the official Microsoft Store.'; return $issues }
    $version = Invoke-Native $winget.Source @('--version')
    $parsed = Convert-Version $version.Output
    if ($version.ExitCode -ne 0 -or $null -eq $parsed -or $parsed -lt [version]'1.10') { $issues += 'WinGet 1.10+ is required. Update Microsoft App Installer.' }
    if ($Mode -eq 'Install') {
        $source = Invoke-Native $winget.Source @('source','list','--name','winget')
        if ($source.ExitCode -ne 0 -or $source.Output -notmatch 'https://cdn\.winget\.microsoft\.com/cache(?:/|\s|$)') { $issues += 'The winget source must be the official Microsoft CDN. No source settings were changed.' }
        $client = New-Object Net.Sockets.TcpClient
        try {
            $pending = $client.BeginConnect('cdn.winget.microsoft.com',443,$null,$null)
            if (-not $pending.AsyncWaitHandle.WaitOne(5000)) { throw 'Connection timeout' }
            $client.EndConnect($pending)
        } catch { $issues += 'Cannot reach the official WinGet CDN. Check network/proxy and run again.' }
        finally { $client.Dispose() }
    }
    return $issues
}

function Test-DockerPrerequisites {
    if ($env:OS -ne 'Windows_NT') { return $false }
    try {
        $features = @(Get-CimInstance Win32_OptionalFeature -ErrorAction Stop | Where-Object { $_.Name -in @('VirtualMachinePlatform','Microsoft-Windows-Subsystem-Linux') -and $_.InstallState -eq 1 })
        $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        return ($features.Count -eq 2 -and $computer.HypervisorPresent)
    } catch { return $false }
}
