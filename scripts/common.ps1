Set-StrictMode -Version 3.0

function Protect-Text {
    param([AllowEmptyString()][string]$Text)
    $value = $Text
    foreach ($path in @($env:USERPROFILE, $env:LOCALAPPDATA)) {
        if (-not [string]::IsNullOrWhiteSpace($path)) { $value = $value.Replace($path, '<user>') }
    }
    $value = $value -replace '(?i)[A-Z]:\\Users\\[^\\\s]+', '<user>'
    $value = $value -replace '(?i)(access_token|refresh_token|api[_-]?key|authorization|password)\s*[=:]\s*\S+', '$1=<redacted>'
    $value = $value -replace '(?i)Bearer\s+\S+', 'Bearer <redacted>'
    $value = $value -replace '\b(?:gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+|sk-[A-Za-z0-9_-]+)\b', '<redacted>'
    $value = $value -replace '\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+', '<redacted>'
    $value = $value -replace '(https?://[^\s?]+)\?[^\s]+', '$1?<redacted>'
    return $value
}

function Invoke-Native {
    param([Parameter(Mandatory)][string]$FilePath, [string[]]$Arguments=@())
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $FilePath @Arguments 2>&1 | ForEach-Object { [string]$_ })
        $code = $LASTEXITCODE
        return [pscustomobject]@{ ExitCode=$code; Output=($output -join "`n") }
    } catch {
        return [pscustomobject]@{ ExitCode=-1; Output=(Protect-Text $_.Exception.Message) }
    } finally { $ErrorActionPreference = $previous }
}

function Update-ProcessPath {
    if ($env:OS -ne 'Windows_NT') { return }
    $parts = @($env:PATH, [Environment]::GetEnvironmentVariable('Path','Machine'), [Environment]::GetEnvironmentVariable('Path','User'))
    $env:PATH = (($parts -join ';').Split(';') | Where-Object { $_ } | Select-Object -Unique) -join ';'
}

function Convert-Version {
    param([AllowNull()][string]$Text)
    if ($Text -match '(\d+\.\d+(?:\.\d+){0,2})') {
        try { return [version]$Matches[1] } catch { return $null }
    }
    return $null
}

function Test-CompatibleVersion {
    param([hashtable]$Package, [AllowNull()][string]$Version)
    $parsed = Convert-Version $Version
    if ($null -eq $parsed) { return $false }
    if ($Package['MinVersion'] -and $parsed -lt [version]$Package['MinVersion']) { return $false }
    if ($Package['AllowedMajors'] -and $parsed.Major -notin $Package['AllowedMajors']) { return $false }
    return $true
}

function New-PackageResult {
    param([string]$Id, [string]$Status, [string]$Action, [string]$Version='', [AllowNull()]$ExitCode=$null, [string]$NextAction='', [string]$RequestedVersion='')
    [pscustomobject]@{ packageId=$Id; selected=$true; detectedVersion=$Version; requestedVersion=$RequestedVersion; action=$Action; status=$Status; installerExitCode=$ExitCode; verification=($Status -in @('PRESENT_COMPATIBLE','INSTALLED')); nextAction=$NextAction }
}

function Get-OverallExitCode {
    param([object[]]$Results)
    if (@($Results | Where-Object { $_.status -eq 'FAILED' }).Count -gt 0) { return 1 }
    if (@($Results | Where-Object { $_.status -in @('ACTION_REQUIRED','REBOOT_REQUIRED') }).Count -gt 0) { return 2 }
    return 0
}

function ConvertTo-SafeResultsJson {
    param([object[]]$Results)
    $safe = @()
    foreach ($result in $Results) {
        $row = [ordered]@{}
        foreach ($property in $result.PSObject.Properties) {
            if ($property.Value -is [string]) { $row[$property.Name] = Protect-Text $property.Value }
            else { $row[$property.Name] = $property.Value }
        }
        $safe += [pscustomobject]$row
    }
    return ConvertTo-Json -InputObject @($safe) -Depth 5
}

function Save-SafeResults {
    param([object[]]$Results)
    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { return }
    $directory = Join-Path $env:LOCALAPPDATA 'MitchellBootstrap\logs'
    [void](New-Item -ItemType Directory -Path $directory -Force)
    $path = Join-Path $directory ((Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.json')
    $json = ConvertTo-SafeResultsJson $Results
    [IO.File]::WriteAllText($path, $json, (New-Object Text.UTF8Encoding($false)))
}
