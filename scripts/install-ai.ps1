function Get-AIExtensionIds {
    param([ValidateSet('None','Codex','Claude','Both')][string]$AI, [hashtable]$Catalogue)
    switch ($AI) {
        'Codex' { return @($Catalogue.Extensions.Codex) }
        'Claude' { return @($Catalogue.Extensions.Claude) }
        'Both' { return @($Catalogue.Extensions.Codex,$Catalogue.Extensions.Claude) }
        default { return @() }
    }
}

function Invoke-AISteps {
    param([string]$AI,[string]$Mode,[hashtable]$Catalogue)
    $ids = @(Get-AIExtensionIds $AI $Catalogue)
    if ($ids.Count -eq 0) { return @() }
    $vscode = @($Catalogue.Packages | Where-Object { $_.Id -eq 'Microsoft.VisualStudioCode' })[0]
    $code = Find-PackageExecutable $vscode
    $installed = @()
    if ($code) {
        $list = Invoke-Native $code @('--list-extensions','--show-versions')
        if ($list.ExitCode -ne 0) { return @(New-PackageResult 'AI' 'ACTION_REQUIRED' 'VERIFY' '' $list.ExitCode 'Cannot list VS Code extensions. Open VS Code once and retry.') }
        $installed = @($list.Output -split '\r?\n')
    }
    $results = @()
    foreach ($id in $ids) {
        $existing = $installed | Where-Object { $_ -match ('^' + [regex]::Escape($id) + '@') } | Select-Object -First 1
        if ($existing) { $results += New-PackageResult $id 'PRESENT_COMPATIBLE' 'SKIP' ($existing -split '@',2)[1]; continue }
        if ($Mode -eq 'Plan') { $results += New-PackageResult $id 'SKIPPED' 'WOULD_INSTALL' '' $null 'Account login remains manual.'; continue }
        if (-not $code -or $Mode -eq 'Verify') { $results += New-PackageResult $id 'ACTION_REQUIRED' 'MISSING' '' $null 'Install VS Code and the selected official extension.'; continue }
        $run = Invoke-Native $code @('--install-extension',$id)
        $check = Invoke-Native $code @('--list-extensions','--show-versions')
        $found = $check.Output -split '\r?\n' | Where-Object { $_ -match ('^' + [regex]::Escape($id) + '@') } | Select-Object -First 1
        if ($run.ExitCode -eq 0 -and $check.ExitCode -eq 0 -and $found) { $results += New-PackageResult $id 'INSTALLED' 'INSTALL' ($found -split '@',2)[1] $run.ExitCode 'Open VS Code and sign in yourself.' }
        else { $results += New-PackageResult $id 'FAILED' 'INSTALL' '' $run.ExitCode 'Extension was not verified. Open Extensions in VS Code; do not purchase another subscription automatically.' }
    }
    return $results
}
