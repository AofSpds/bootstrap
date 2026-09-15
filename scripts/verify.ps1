function Find-PackageExecutable {
    param([hashtable]$Package)
    if ($Package['Exe']) {
        $command = Get-Command $Package['Exe'] -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command -and -not ($Package['Group'] -eq 'Python' -and $command.Source -match '\\WindowsApps\\')) { return $command.Source }
    }
    foreach ($candidate in @($Package['Paths'])) {
        if (-not $candidate) { continue }
        $expanded = [Environment]::ExpandEnvironmentVariables($candidate)
        if (Test-Path -LiteralPath $expanded -PathType Leaf) { return $expanded }
    }
    return $null
}

function Find-PackageRegistration {
    param([hashtable]$Package)
    $roots = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
    foreach ($root in $roots) {
        $entries = @(Get-ItemProperty -Path $root -ErrorAction SilentlyContinue | Select-Object DisplayName,DisplayVersion)
        foreach ($entry in $entries) {
            foreach ($pattern in @($Package['Names'])) {
                if ($pattern -and $entry.DisplayName -like $pattern) { return $entry }
            }
        }
    }
    return $null
}

function Get-PackageState {
    param([hashtable]$Package)
    if ($Package['Probe'] -eq 'Appx') {
        $appx = Get-AppxPackage -Name $Package['AppxName'] -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($appx) { return [pscustomobject]@{ Present=$true; Version=[string]$appx.Version; Compatible=(Test-CompatibleVersion $Package ([string]$appx.Version)); Detail='Appx registration' } }
        return [pscustomobject]@{ Present=$false; Version=''; Compatible=$false; Detail='Not installed' }
    }
    $file = Find-PackageExecutable $Package
    $registration = Find-PackageRegistration $Package
    if ($file) {
        if ($Package['Probe'] -eq 'File') {
            $versionText = (Get-Item -LiteralPath $file).VersionInfo.ProductVersion
            if (-not (Convert-Version $versionText) -and $registration) { $versionText = $registration.DisplayVersion }
            $code = 0
        } else {
            $probe = Invoke-Native $file @($Package['Args'])
            $versionText = $probe.Output
            $code = $probe.ExitCode
        }
        $parsed = Convert-Version $versionText
        $version = ''
        if ($null -ne $parsed) { $version = $parsed.ToString() }
        $compatible = ($code -eq 0 -and (Test-CompatibleVersion $Package $version))
        $detail = 'Executable/version verified'
        foreach ($companion in @($Package['Companions'])) {
            if (-not $companion) { continue }
            $companionPath = Join-Path (Split-Path -Parent $file) $companion
            if (-not (Test-Path -LiteralPath $companionPath -PathType Leaf)) { $compatible=$false; $detail='Node installation is missing npm/npx'; continue }
            $check = Invoke-Native $companionPath @('--version')
            if ($check.ExitCode -ne 0 -or -not (Convert-Version $check.Output)) { $compatible=$false; $detail='npm/npx verification failed' }
        }
        return [pscustomobject]@{ Present=$true; Version=$version; Compatible=$compatible; Detail=$detail }
    }
    if ($registration) { return [pscustomobject]@{ Present=$true; Version=[string]$registration.DisplayVersion; Compatible=$false; Detail='Registration exists but executable was not found. Repair manually; do not install over it.' } }
    return [pscustomobject]@{ Present=$false; Version=''; Compatible=$false; Detail='Not installed' }
}
