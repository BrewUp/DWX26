[CmdletBinding()]
param([string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { $script:failures.Add($Message) }
}

$manifestPath = Join-Path $RepositoryRoot '.bmad-harness\manifest.json'
Assert-True (Test-Path -LiteralPath $manifestPath) 'manifest.json must exist'

if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    Assert-True ($manifest.schemaVersion -eq 1) 'schemaVersion must be 1'
    Assert-True ($manifest.governance.Count -eq 3) 'three governance documents are required'
    Assert-True ($manifest.requiredRuleIds.bc.Count -gt 0) 'BC rule IDs are required'
    Assert-True ($manifest.requiredRuleIds.ar.Count -gt 0) 'AR rule IDs are required'
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output 'BMAD harness tests passed.'
