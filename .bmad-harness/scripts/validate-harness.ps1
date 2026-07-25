[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$ArtifactRoot
)

$ErrorActionPreference = 'Stop'
$script:Findings = [System.Collections.Generic.List[pscustomobject]]::new()

function Add-Finding {
    param(
        [ValidateSet('PASS', 'CONCERNS', 'FAIL')][string]$Decision,
        [string]$CheckId,
        [string]$Message
    )

    $singleLineMessage = ($Message -replace '\s+', ' ').Trim()
    [void]$script:Findings.Add([pscustomobject]@{
        Decision = $Decision
        CheckId = $CheckId
        Message = $singleLineMessage
    })
}

function Resolve-HarnessPath {
    param([string]$RepositoryRoot, [string]$RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw 'A harness reference cannot be empty.'
    }

    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        throw "Harness reference must be repository-relative: $RelativePath"
    }

    $rootPath = [System.IO.Path]::GetFullPath($RepositoryRoot)
    $normalizedRelativePath = $RelativePath.Replace(
        [System.IO.Path]::AltDirectorySeparatorChar,
        [System.IO.Path]::DirectorySeparatorChar
    )
    $resolvedPath = [System.IO.Path]::GetFullPath(
        [System.IO.Path]::Combine($rootPath, $normalizedRelativePath)
    )
    $rootPrefix = $rootPath.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar

    if (
        -not $resolvedPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
        -not $resolvedPath.Equals($rootPath, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
        throw "Harness reference escapes the repository root: $RelativePath"
    }

    return $resolvedPath
}

function Get-RuleIds {
    param([string[]]$GovernancePaths, [string]$Prefix)

    $ruleIds = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $pattern = "(?m)^###\s+($([regex]::Escape($Prefix))-\d{3})(?:\s|$)"

    foreach ($governancePath in $GovernancePaths) {
        if (-not (Test-Path -LiteralPath $governancePath -PathType Leaf)) {
            continue
        }

        $text = Get-Content -Raw -LiteralPath $governancePath
        foreach ($match in [regex]::Matches($text, $pattern)) {
            [void]$ruleIds.Add($match.Groups[1].Value)
        }
    }

    return @($ruleIds | Sort-Object)
}

function Test-StringSequence {
    param([object[]]$Actual, [string[]]$Expected)

    $actualValues = @($Actual | ForEach-Object { [string]$_ })
    if ($actualValues.Count -ne $Expected.Count) {
        return $false
    }

    for ($index = 0; $index -lt $Expected.Count; $index++) {
        if ($actualValues[$index] -cne $Expected[$index]) {
            return $false
        }
    }

    return $true
}

function Test-StringSet {
    param([object[]]$Actual, [string[]]$Expected)

    $actualValues = @($Actual | ForEach-Object { [string]$_ } | Sort-Object)
    $expectedValues = @($Expected | Sort-Object)
    return Test-StringSequence $actualValues $expectedValues
}

function Get-FailCount {
    return @($script:Findings | Where-Object { $_.Decision -eq 'FAIL' }).Count
}

function Test-ManifestReferences {
    param([pscustomobject]$Manifest, [string]$RepositoryRoot)

    $startingFailCount = Get-FailCount
    $expectedGovernance = @(
        '.bmad-harness/governance/brewup-sales-order-confirmation.md',
        '.bmad-harness/governance/brewup-module-structure.md',
        '.bmad-harness/governance/gate-contract.md'
    )
    $expectedBcRuleIds = @('BC-000', 'BC-003', 'BC-007', 'BC-009')
    $expectedArRuleIds = @(
        'AR-000',
        'AR-001',
        'AR-002',
        'AR-003',
        'AR-008',
        'AR-010',
        'AR-016'
    )
    $expectedOverrides = @(
        [pscustomobject]@{ path = '_bmad/custom/bmad-agent-analyst.toml'; kind = 'agent'; skill = 'bmad-agent-analyst' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-agent-pm.toml'; kind = 'agent'; skill = 'bmad-agent-pm' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-agent-architect.toml'; kind = 'agent'; skill = 'bmad-agent-architect' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-agent-dev.toml'; kind = 'agent'; skill = 'bmad-agent-dev' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-product-brief.toml'; kind = 'workflow'; skill = 'bmad-product-brief' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-prd.toml'; kind = 'workflow'; skill = 'bmad-prd' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-architecture.toml'; kind = 'workflow'; skill = 'bmad-architecture' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-create-epics-and-stories.toml'; kind = 'workflow'; skill = 'bmad-create-epics-and-stories' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-check-implementation-readiness.toml'; kind = 'workflow'; skill = 'bmad-check-implementation-readiness' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-create-story.toml'; kind = 'workflow'; skill = 'bmad-create-story' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-dev-story.toml'; kind = 'workflow'; skill = 'bmad-dev-story' },
        [pscustomobject]@{ path = '_bmad/custom/bmad-code-review.toml'; kind = 'workflow'; skill = 'bmad-code-review' }
    )
    $expectedAgents = @(
        [pscustomobject]@{ path = '.github/agents/bmad-brewup-load-domain-context.agent.md'; gate = 'analysis.context' },
        [pscustomobject]@{ path = '.github/agents/bmad-brewup-product-brief-guard.agent.md'; gate = 'analysis.product-brief' },
        [pscustomobject]@{ path = '.github/agents/bmad-brewup-prd-guard.agent.md'; gate = 'planning.prd' },
        [pscustomobject]@{ path = '.github/agents/bmad-brewup-architecture-readiness.agent.md'; gate = 'solutioning.architecture-readiness' },
        [pscustomobject]@{ path = '.github/agents/bmad-brewup-architecture-guard.agent.md'; gate = 'solutioning.architecture' },
        [pscustomobject]@{ path = '.github/agents/bmad-brewup-epics-stories-guard.agent.md'; gate = 'solutioning.epics-stories' },
        [pscustomobject]@{ path = '.github/agents/bmad-brewup-implementation-readiness.agent.md'; gate = 'solutioning.implementation-readiness' },
        [pscustomobject]@{ path = '.github/agents/bmad-brewup-story-guard.agent.md'; gate = 'implementation.story' },
        [pscustomobject]@{ path = '.github/agents/bmad-brewup-code-review-guard.agent.md'; gate = 'implementation.code-review' }
    )
    $expectedPhaseCoverage = [ordered]@{
        analysis = @('bmad-product-brief')
        planning = @('bmad-prd')
        solutioning = @(
            'bmad-architecture',
            'bmad-create-epics-and-stories',
            'bmad-check-implementation-readiness'
        )
        implementation = @('bmad-create-story', 'bmad-dev-story', 'bmad-code-review')
    }

    if ($Manifest.schemaVersion -ne 1) {
        Add-Finding FAIL 'manifest-schema' 'schemaVersion must be 1.'
    }

    if (-not (Test-StringSequence @($Manifest.governance) $expectedGovernance)) {
        Add-Finding FAIL 'manifest-governance' 'Governance references must match the three canonical paths in order.'
    }

    if (-not (Test-StringSequence @($Manifest.requiredRuleIds.bc) $expectedBcRuleIds)) {
        Add-Finding FAIL 'manifest-rules-bc' 'The required BC rule ID list does not match the harness contract.'
    }
    if (-not (Test-StringSequence @($Manifest.requiredRuleIds.ar) $expectedArRuleIds)) {
        Add-Finding FAIL 'manifest-rules-ar' 'The required AR rule ID list does not match the harness contract.'
    }

    $manifestOverrides = @($Manifest.overrides)
    if ($manifestOverrides.Count -ne $expectedOverrides.Count) {
        Add-Finding FAIL 'manifest-overrides' "Expected $($expectedOverrides.Count) exact override registrations; found $($manifestOverrides.Count)."
    }
    foreach ($expectedOverride in $expectedOverrides) {
        $matches = @($manifestOverrides | Where-Object {
            $_.path -ceq $expectedOverride.path -and
            $_.kind -ceq $expectedOverride.kind -and
            $_.skill -ceq $expectedOverride.skill
        })
        if ($matches.Count -ne 1) {
            Add-Finding FAIL 'manifest-overrides' "Missing or duplicated exact override registration: $($expectedOverride.path)."
        }
    }

    $manifestAgents = @($Manifest.agents)
    if ($manifestAgents.Count -ne $expectedAgents.Count) {
        Add-Finding FAIL 'manifest-agents' "Expected $($expectedAgents.Count) exact agent registrations; found $($manifestAgents.Count)."
    }
    foreach ($expectedAgent in $expectedAgents) {
        $matches = @($manifestAgents | Where-Object {
            $_.path -ceq $expectedAgent.path -and
            $_.gate -ceq $expectedAgent.gate -and
            $_.readOnly -eq $true
        })
        if ($matches.Count -ne 1) {
            Add-Finding FAIL 'manifest-agents' "Missing or malformed exact agent registration: $($expectedAgent.path)."
        }
    }

    $phaseNames = @($Manifest.phaseCoverage.psobject.Properties.Name)
    if (-not (Test-StringSet $phaseNames @($expectedPhaseCoverage.Keys))) {
        Add-Finding FAIL 'manifest-phases' 'phaseCoverage must contain exactly analysis, planning, solutioning, and implementation.'
    }
    foreach ($phase in $expectedPhaseCoverage.Keys) {
        $property = $Manifest.phaseCoverage.psobject.Properties[$phase]
        if ($null -eq $property -or -not (Test-StringSequence @($property.Value) $expectedPhaseCoverage[$phase])) {
            Add-Finding FAIL 'manifest-phases' "Phase '$phase' does not register the exact required workflow sequence."
        }
    }

    $registeredWorkflowSkills = @(
        $manifestOverrides |
            Where-Object { $_.kind -ceq 'workflow' } |
            ForEach-Object { [string]$_.skill }
    )
    $phaseWorkflowSkills = @(
        foreach ($phase in $phaseNames) {
            @($Manifest.phaseCoverage.$phase) | ForEach-Object { [string]$_ }
        }
    )
    if (-not (Test-StringSet $phaseWorkflowSkills $registeredWorkflowSkills)) {
        Add-Finding FAIL 'manifest-phase-registration' 'Every workflow override must be registered exactly once across phaseCoverage.'
    } elseif (@($phaseWorkflowSkills | Group-Object | Where-Object Count -ne 1).Count -gt 0) {
        Add-Finding FAIL 'manifest-phase-registration' 'A workflow is duplicated across phaseCoverage.'
    }

    $allReferences = @(
        $Manifest.governance
        $manifestOverrides | ForEach-Object { $_.path }
        $manifestAgents | ForEach-Object { $_.path }
        '_bmad-output/project-context.md'
    )
    $resolvedReferences = [System.Collections.Generic.List[string]]::new()
    foreach ($reference in $allReferences) {
        try {
            $resolvedPath = Resolve-HarnessPath $RepositoryRoot ([string]$reference)
            [void]$resolvedReferences.Add($resolvedPath)
            if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
                Add-Finding FAIL 'manifest-reference' "Referenced file is missing: $reference."
            }
        } catch {
            Add-Finding FAIL 'manifest-reference' $_.Exception.Message
        }
    }

    $governancePaths = @(
        foreach ($reference in $expectedGovernance) {
            try {
                Resolve-HarnessPath $RepositoryRoot $reference
            } catch {
                $null
            }
        }
    ) | Where-Object { $null -ne $_ }
    $bcRuleIds = @(Get-RuleIds $governancePaths 'BC')
    $arRuleIds = @(Get-RuleIds $governancePaths 'AR')
    foreach ($requiredRuleId in $Manifest.requiredRuleIds.bc) {
        if ($bcRuleIds -cnotcontains [string]$requiredRuleId) {
            Add-Finding FAIL 'rule-coverage' "Required rule is absent from governance: $requiredRuleId."
        }
    }
    foreach ($requiredRuleId in $Manifest.requiredRuleIds.ar) {
        if ($arRuleIds -cnotcontains [string]$requiredRuleId) {
            Add-Finding FAIL 'rule-coverage' "Required rule is absent from governance: $requiredRuleId."
        }
    }

    $referencedRuleIds = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($resolvedReference in $resolvedReferences) {
        if (-not (Test-Path -LiteralPath $resolvedReference -PathType Leaf)) {
            continue
        }

        $text = Get-Content -Raw -LiteralPath $resolvedReference
        foreach ($match in [regex]::Matches($text, '\b(?:BC|AR)-\d{3}\b')) {
            [void]$referencedRuleIds.Add($match.Value)
        }
    }
    foreach ($ruleId in $referencedRuleIds) {
        if (
            ($ruleId.StartsWith('BC-', [System.StringComparison]::Ordinal) -and $bcRuleIds -cnotcontains $ruleId) -or
            ($ruleId.StartsWith('AR-', [System.StringComparison]::Ordinal) -and $arRuleIds -cnotcontains $ruleId)
        ) {
            Add-Finding FAIL 'rule-reference' "Overlay content references an unknown governance rule: $ruleId."
        }
    }

    $gateContractPath = Resolve-HarnessPath $RepositoryRoot '.bmad-harness/governance/gate-contract.md'
    if (Test-Path -LiteralPath $gateContractPath -PathType Leaf) {
        $gateContractText = Get-Content -Raw -LiteralPath $gateContractPath
        if (
            $gateContractText -notmatch '(?s)## Decision.*## Required report headings.*1\.\s+Decision.*2\.\s+Scope.*3\.\s+Findings.*4\.\s+Open decisions.*5\.\s+Traceability'
        ) {
            Add-Finding FAIL 'gate-contract' 'The gate contract must contain all five required report headings in order.'
        }
        if ($gateContractText -notmatch 'PASS.*CONCERNS.*FAIL') {
            Add-Finding FAIL 'gate-contract' 'The gate contract must define PASS, CONCERNS, and FAIL.'
        }
    }

    if ((Get-FailCount) -eq $startingFailCount) {
        Add-Finding PASS 'manifest-references' 'Manifest paths, rules, registrations, and phase coverage are valid.'
    }
}

function Test-OverrideShape {
    param([pscustomobject]$Manifest, [string]$RepositoryRoot)

    $startingFailCount = Get-FailCount
    $governanceFacts = @(
        'file:{project-root}/.bmad-harness/governance/brewup-sales-order-confirmation.md',
        'file:{project-root}/.bmad-harness/governance/brewup-module-structure.md',
        'file:{project-root}/.bmad-harness/governance/gate-contract.md'
    )
    $roleFacts = @{
        'bmad-agent-analyst' = 'Preserve ubiquitous language and open questions.'
        'bmad-agent-pm' = 'Express ownership in requirements and acceptance criteria.'
        'bmad-agent-architect' = 'Map business authority to explicit module structure.'
        'bmad-agent-dev' = 'Implement only approved story decisions and preserve module boundaries.'
    }
    $workflowCompletionFacts = @{
        'bmad-product-brief' = 'Identify governing authorities and unresolved policies.'
        'bmad-prd' = 'Validate requirements and acceptance criteria against BC-###.'
        'bmad-architecture' = 'Validate BC-###, AR-###, module placement, dependencies, and tests.'
        'bmad-create-epics-and-stories' = 'Preserve traceability and do not convert open decisions into work.'
        'bmad-check-implementation-readiness' = 'Emit exactly PASS, CONCERNS, or FAIL.'
        'bmad-create-story' = 'Require affected modules, rule IDs, acceptance criteria, and tests.'
        'bmad-dev-story' = 'Implement only approved decisions and stop on unresolved blocking policy.'
        'bmad-code-review' = 'Cite file evidence and return changes requested for critical violations.'
    }
    $commonCompletionFact = 'Report applicable BC-### and AR-### traceability and do not claim readiness when a critical rule is violated.'

    foreach ($override in @($Manifest.overrides)) {
        $relativePath = [string]$override.path
        try {
            $path = Resolve-HarnessPath $RepositoryRoot $relativePath
        } catch {
            continue
        }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }

        $text = Get-Content -Raw -LiteralPath $path
        $expectedTable = [string]$override.kind
        $tableMatches = [regex]::Matches($text, '(?m)^\s*\[(?<name>[^\]]+)\]\s*$')
        if (
            $tableMatches.Count -ne 1 -or
            $tableMatches[0].Groups['name'].Value -cne $expectedTable
        ) {
            Add-Finding FAIL 'override-table' "$relativePath must contain only the [$expectedTable] TOML table."
        }

        $activationMatch = [regex]::Match(
            $text,
            '(?ms)^activation_steps_prepend\s*=\s*\[(?<body>.*?)^\]\s*$'
        )
        if (-not $activationMatch.Success) {
            Add-Finding FAIL 'override-activation' "$relativePath must define activation_steps_prepend as an array."
        } elseif ($activationMatch.Groups['body'].Value -notmatch '\{project-root\}/') {
            Add-Finding FAIL 'override-project-root' "$relativePath activation must use a {project-root}/ reference."
        }

        $factsMatch = [regex]::Match(
            $text,
            '(?ms)^persistent_facts\s*=\s*\[(?<body>.*?)^\]\s*$'
        )
        if (-not $factsMatch.Success) {
            Add-Finding FAIL 'override-facts' "$relativePath must define persistent_facts as an array."
            continue
        }

        $quotedFacts = @(
            [regex]::Matches($factsMatch.Groups['body'].Value, '(?m)^\s*"(?<value>[^"\r\n]+)"\s*,?\s*$') |
                ForEach-Object { $_.Groups['value'].Value }
        )
        $expectedFactCount = if ($expectedTable -ceq 'workflow') { 3 } else { 4 }
        if ($quotedFacts.Count -ne $expectedFactCount) {
            Add-Finding FAIL 'override-facts' "$relativePath must contain exactly $expectedFactCount sparse persistent facts."
        }

        $fileFacts = @($quotedFacts | Where-Object { $_.StartsWith('file:', [System.StringComparison]::Ordinal) })
        if (-not (Test-StringSequence $fileFacts $governanceFacts)) {
            Add-Finding FAIL 'override-governance-facts' "$relativePath must load the three exact governance facts in order."
        }

        foreach ($projectRootReference in [regex]::Matches($text, '(?<value>[^"\r\n]*\{project-root\}[^"\r\n]*)')) {
            if ($projectRootReference.Groups['value'].Value -notmatch '\{project-root\}/') {
                Add-Finding FAIL 'override-project-root' "$relativePath contains a malformed {project-root} reference."
            }
        }

        if ($expectedTable -ceq 'agent') {
            $requiredRoleFact = [string]$roleFacts[[string]$override.skill]
            if ([string]::IsNullOrWhiteSpace($requiredRoleFact) -or $quotedFacts -cnotcontains $requiredRoleFact) {
                Add-Finding FAIL 'override-role-fact' "$relativePath is missing its exact role-specific fact."
            }
            if ($text -match '(?m)^on_complete\s*=') {
                Add-Finding FAIL 'override-on-complete' "$relativePath is an agent override and must not define on_complete."
            }
        } elseif ($expectedTable -ceq 'workflow') {
            $onCompleteMatches = [regex]::Matches(
                $text,
                '(?m)^on_complete\s*=\s*"(?<value>[^"\r\n]+)"\s*$'
            )
            if ($onCompleteMatches.Count -ne 1) {
                Add-Finding FAIL 'override-on-complete' "$relativePath must define one non-empty on_complete string."
            } else {
                $onComplete = $onCompleteMatches[0].Groups['value'].Value
                $requiredWorkflowFact = [string]$workflowCompletionFacts[[string]$override.skill]
                if (
                    [string]::IsNullOrWhiteSpace($requiredWorkflowFact) -or
                    -not $onComplete.StartsWith($requiredWorkflowFact, [System.StringComparison]::Ordinal)
                ) {
                    Add-Finding FAIL 'override-on-complete' "$relativePath is missing its exact workflow completion fact."
                }
                if (-not $onComplete.EndsWith($commonCompletionFact, [System.StringComparison]::Ordinal)) {
                    Add-Finding FAIL 'override-on-complete' "$relativePath is missing the common BC/AR completion contract."
                }
            }
        } else {
            Add-Finding FAIL 'override-kind' "$relativePath has unsupported manifest kind '$expectedTable'."
        }
    }

    if ((Get-FailCount) -eq $startingFailCount) {
        Add-Finding PASS 'override-shape' 'All agent and workflow overrides have the required sparse TOML shape and exact facts.'
    }
}

function Test-AgentContracts {
    param([pscustomobject]$Manifest, [string]$RepositoryRoot)

    $startingFailCount = Get-FailCount
    $canonicalPaths = @{
        '.github/agents/bmad-brewup-product-brief-guard.agent.md' = @(
            '_bmad-output/planning-artifacts/product-brief.md',
            '_bmad-output/planning-artifacts/product-brief/index.md'
        )
        '.github/agents/bmad-brewup-prd-guard.agent.md' = @(
            '_bmad-output/planning-artifacts/prd.md',
            '_bmad-output/planning-artifacts/prd/index.md'
        )
        '.github/agents/bmad-brewup-architecture-readiness.agent.md' = @(
            '_bmad-output/planning-artifacts/prd.md',
            '_bmad-output/planning-artifacts/prd/index.md'
        )
        '.github/agents/bmad-brewup-architecture-guard.agent.md' = @(
            '_bmad-output/planning-artifacts/prd.md',
            '_bmad-output/planning-artifacts/prd/index.md',
            '_bmad-output/planning-artifacts/ARCHITECTURE-SPINE.md',
            '_bmad-output/planning-artifacts/architecture.md',
            '_bmad-output/planning-artifacts/architecture/index.md'
        )
    }

    foreach ($agent in @($Manifest.agents)) {
        $relativePath = [string]$agent.path
        try {
            $path = Resolve-HarnessPath $RepositoryRoot $relativePath
        } catch {
            continue
        }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }

        $text = Get-Content -Raw -LiteralPath $path
        $frontmatterMatch = [regex]::Match(
            $text,
            '\A---\r?\n(?<frontmatter>[\s\S]*?)\r?\n---\r?\n'
        )
        if (-not $frontmatterMatch.Success) {
            Add-Finding FAIL 'agent-frontmatter' "$relativePath must have bounded YAML frontmatter."
        } else {
            $frontmatter = $frontmatterMatch.Groups['frontmatter'].Value
            if ($frontmatter -notmatch '(?m)^description:\s*\S.+$') {
                Add-Finding FAIL 'agent-frontmatter' "$relativePath needs a non-empty frontmatter description."
            }
            if ($frontmatter -notmatch '(?m)^tools:\s*\["read",\s*"search"\]\s*$') {
                Add-Finding FAIL 'agent-frontmatter' "$relativePath must allow only read and search tools."
            }
        }

        if ($agent.readOnly -ne $true -or $text -notmatch '(?i)read-only|do not (?:create|edit)|never edit') {
            Add-Finding FAIL 'agent-read-only' "$relativePath must declare and describe a read-only contract."
        }
        if ($text -notmatch '(?s)PASS.*CONCERNS.*FAIL') {
            Add-Finding FAIL 'agent-decisions' "$relativePath must define PASS, CONCERNS, and FAIL in order."
        }
        if ($text -notmatch 'BC-###') {
            Add-Finding FAIL 'agent-rules' "$relativePath must inspect BC-### rules."
        }
        if ($text -notmatch 'gate-contract\.md') {
            Add-Finding FAIL 'agent-gate-contract' "$relativePath must load gate-contract.md."
        }
        if ($text -notmatch '(?is)governance file is missing.*FAIL') {
            Add-Finding FAIL 'agent-governance-failure' "$relativePath must return FAIL when governance is missing."
        }
        if (
            $text -notmatch '(?s)1\.\s*`Decision`.*2\.\s*`Scope`.*3\.\s*`Findings`.*4\.\s*`Open decisions`.*5\.\s*`Traceability`'
        ) {
            Add-Finding FAIL 'agent-headings' "$relativePath must require all five gate headings in order."
        }
        if ($text -notmatch [regex]::Escape('_bmad-output/project-context.md')) {
            Add-Finding FAIL 'agent-context-path' "$relativePath must load the canonical project-context path."
        }
        foreach ($canonicalPath in @($canonicalPaths[$relativePath])) {
            if ($text -notmatch [regex]::Escape($canonicalPath)) {
                Add-Finding FAIL 'agent-artifact-path' "$relativePath must cite canonical artifact path $canonicalPath."
            }
        }
    }

    if ((Get-FailCount) -eq $startingFailCount) {
        Add-Finding PASS 'agent-contracts' 'Copilot agents have valid frontmatter, read-only gate contracts, and canonical paths.'
    }
}

function Test-NoInstalledCore {
    param([pscustomobject]$Manifest, [string]$RepositoryRoot)

    $startingFailCount = Get-FailCount
    $prohibitedPaths = @(
        '_bmad/bmm',
        '_bmad/core',
        '_bmad/scripts',
        '_bmad/config.toml'
    )
    foreach ($relativePath in $prohibitedPaths) {
        $path = Resolve-HarnessPath $RepositoryRoot $relativePath
        if (Test-Path -LiteralPath $path) {
            Add-Finding FAIL 'no-installed-core' "Installed BMAD core path must be absent: $relativePath."
        }
    }

    $overlayReferences = @(
        $Manifest.governance
        @($Manifest.overrides) | ForEach-Object { $_.path }
        @($Manifest.agents) | ForEach-Object { $_.path }
        '_bmad-output/project-context.md'
    )
    foreach ($relativePath in $overlayReferences) {
        try {
            $path = Resolve-HarnessPath $RepositoryRoot ([string]$relativePath)
        } catch {
            continue
        }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }

        $text = Get-Content -Raw -LiteralPath $path
        if ($text -match '(?i)(?:^|[^A-Za-z0-9_])_bmad[/\\](?:bmm|core|scripts)(?:[/\\]|$)') {
            Add-Finding FAIL 'no-installed-core-reference' "$relativePath references an installed BMAD core path."
        }
    }

    if ((Get-FailCount) -eq $startingFailCount) {
        Add-Finding PASS 'no-installed-core' 'No BMAD installed-core directories or references are present.'
    }
}

function Test-ArtifactRules {
    param([string]$ArtifactRoot)

    $startingFailCount = Get-FailCount
    if (-not (Test-Path -LiteralPath $ArtifactRoot -PathType Container)) {
        Add-Finding FAIL 'artifact-root' "Artifact root does not exist or is not a directory: $ArtifactRoot."
        return
    }

    $artifactRules = @(
        @{
            Id = 'BC-003/BC-007'
            Pattern = 'SalesOrder\.Confirm.*(authoriz|reserv)'
            Message = 'Sales must not authorize payment or reserve stock.'
        },
        @{
            Id = 'AR-001/AR-016'
            Pattern = 'src[/\\]Sales[/\\].*Payment'
            Message = 'Payment implementation must not be collapsed into Sales.'
        },
        @{
            Id = 'BC-000'
            Pattern = 'retry exactly three times.*mark payment declined'
            Message = 'The story invents provider timeout policy.'
        }
    )

    [string[]]$markdownPaths = @(
        Get-ChildItem -LiteralPath $ArtifactRoot -Recurse -File -Filter '*.md' |
            ForEach-Object { $_.FullName }
    )
    [System.Array]::Sort($markdownPaths, [System.StringComparer]::OrdinalIgnoreCase)

    if ($markdownPaths.Count -eq 0) {
        Add-Finding CONCERNS 'artifact-files' "No Markdown artifacts were found under $ArtifactRoot."
    }

    foreach ($markdownPath in $markdownPaths) {
        $text = Get-Content -Raw -LiteralPath $markdownPath
        $relativePath = [System.IO.Path]::GetRelativePath($ArtifactRoot, $markdownPath).Replace('\', '/')
        foreach ($rule in $artifactRules) {
            if (
                [regex]::IsMatch(
                    $text,
                    [string]$rule.Pattern,
                    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                        [System.Text.RegularExpressions.RegexOptions]::Singleline
                )
            ) {
                Add-Finding FAIL ([string]$rule.Id) "$($rule.Message) Evidence: $relativePath."
            }
        }
    }

    if ((Get-FailCount) -eq $startingFailCount) {
        Add-Finding PASS 'artifact-rules' "Artifact lint found no named authority, module, or policy violations in $($markdownPaths.Count) Markdown file(s)."
    }
}

try {
    $resolvedRepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
    if (-not (Test-Path -LiteralPath $resolvedRepositoryRoot -PathType Container)) {
        throw 'RepositoryRoot must be a directory.'
    }
} catch {
    Add-Finding FAIL 'repository-root' "Repository root is invalid: $RepositoryRoot. $($_.Exception.Message)"
}

$manifest = $null
if ((Get-FailCount) -eq 0) {
    try {
        $manifestPath = Resolve-HarnessPath $resolvedRepositoryRoot '.bmad-harness/manifest.json'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            Add-Finding FAIL 'manifest-json' 'Manifest file is missing: .bmad-harness/manifest.json.'
        } else {
            $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
            if ($null -eq $manifest -or $manifest -isnot [pscustomobject]) {
                Add-Finding FAIL 'manifest-json' 'Manifest JSON must contain one object.'
            } else {
                Add-Finding PASS 'manifest-json' 'Manifest JSON parsed successfully.'
            }
        }
    } catch {
        Add-Finding FAIL 'manifest-json' "Manifest JSON parsing failed: $($_.Exception.Message)"
    }
}

if ($null -ne $manifest) {
    Test-ManifestReferences $manifest $resolvedRepositoryRoot
    Test-OverrideShape $manifest $resolvedRepositoryRoot
    Test-AgentContracts $manifest $resolvedRepositoryRoot
    Test-NoInstalledCore $manifest $resolvedRepositoryRoot
}

if (-not [string]::IsNullOrWhiteSpace($ArtifactRoot)) {
    try {
        $resolvedArtifactRoot = (Resolve-Path -LiteralPath $ArtifactRoot).Path
        Test-ArtifactRules $resolvedArtifactRoot
    } catch {
        Add-Finding FAIL 'artifact-root' "Artifact root is invalid: $ArtifactRoot. $($_.Exception.Message)"
    }
}

foreach ($finding in $script:Findings) {
    Write-Output "$($finding.Decision) [$($finding.CheckId)] $($finding.Message)"
}

if (@($script:Findings | Where-Object { $_.Decision -eq 'FAIL' }).Count -gt 0) {
    exit 1
}

exit 0
