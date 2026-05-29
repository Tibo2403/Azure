function Assert-True {
  param(
    [bool] $Condition,
    [string] $Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

function Assert-Matches {
  param(
    [string] $Value,
    [string] $Pattern,
    [string] $Message
  )

  if ($Value -notmatch $Pattern) {
    throw $Message
  }
}

Describe "AZ-305 repository production readiness" {
  It "has GitHub validation and what-if workflows" {
    Assert-True (Test-Path ".github/workflows/bicep-validate.yml") "Missing bicep validation workflow."
    Assert-True (Test-Path ".github/workflows/azure-whatif.yml") "Missing Azure what-if workflow."
    Assert-True (Test-Path ".github/workflows/codeql.yml") "Missing CodeQL workflow."
    Assert-True (Test-Path ".github/workflows/lab-cleanup.yml") "Missing lab cleanup workflow."
  }

  It "has scenario parameter files for major AZ-305 themes" {
    @(
      "params/minimal.dev.bicepparam",
      "params/secure.dev.bicepparam",
      "params/hubspoke.prod.bicepparam",
      "params/multiregion.prod.bicepparam",
      "params/data-platform.prod.bicepparam",
      "params/identity-access.prod.bicepparam",
      "params/observability.prod.bicepparam",
      "params/backup-dr.prod.bicepparam",
      "params/compute-platform.dev.bicepparam",
      "params/app-integration.prod.bicepparam",
      "params/migration-toolkit.prod.bicepparam",
      "params/sentinel-soc.prod.bicepparam",
      "params/finops.prod.bicepparam",
      "params/zero-public-access.prod.bicepparam"
    ) | ForEach-Object { Assert-True (Test-Path $_) "Missing scenario parameter file: $_" }
  }

  It "has operational runbooks" {
    @(
      "docs/runbooks/incident-response.md",
      "docs/runbooks/backup-restore.md",
      "docs/runbooks/sql-failover.md",
      "docs/runbooks/secret-rotation.md",
      "docs/runbooks/lab-cleanup.md"
    ) | ForEach-Object { Assert-True (Test-Path $_) "Missing runbook: $_" }
  }

  It "documents Well-Architected and CAF decisions" {
    Assert-True (Test-Path "docs/well-architected-matrix.md") "Missing Well-Architected matrix."
    Assert-True (Test-Path "docs/cloud-adoption-framework.md") "Missing CAF documentation."
    Assert-True (Test-Path "docs/github-oidc-setup.md") "Missing GitHub OIDC setup documentation."
    Assert-True (Test-Path "docs/az-305-study-notes.md") "Missing AZ-305 study notes."
    Assert-True (Test-Path "docs/scenario-catalog.md") "Missing scenario catalog."
    Assert-True (Test-Path "docs/portfolio-summary.md") "Missing portfolio summary."
  }

  It "has architecture diagrams for core scenarios" {
    @(
      "docs/diagrams/hub-spoke.md",
      "docs/diagrams/multi-region.md",
      "docs/diagrams/data-platform.md",
      "docs/diagrams/sentinel-soc.md",
      "docs/diagrams/migration-path.md"
    ) | ForEach-Object { Assert-True (Test-Path $_) "Missing architecture diagram: $_" }
  }

  It "has OIDC and cost cleanup helper scripts" {
    Assert-True (Test-Path "scripts/setup-github-oidc.ps1") "Missing OIDC setup script."
    Assert-True (Test-Path "scripts/list-costly-lab-resources.ps1") "Missing costly resource listing script."
    Assert-True (Test-Path "scripts/deploy-zero-public-access.ps1") "Missing zero public access deployment script."
  }

  It "has ADRs for major architecture decisions" {
    @(
      "docs/adr/0001-hub-spoke-network.md",
      "docs/adr/0002-front-door-vs-application-gateway.md",
      "docs/adr/0003-compute-platform-choice.md",
      "docs/adr/0004-sentinel-for-soc.md",
      "docs/adr/0005-private-endpoints.md"
    ) | ForEach-Object { Assert-True (Test-Path $_) "Missing ADR: $_" }
  }

  It "has task runner and sample outputs" {
    Assert-True (Test-Path "Taskfile.yml") "Missing Taskfile."
    Assert-True (Test-Path "docs/sample-outputs/validate-success.txt") "Missing validation sample output."
    Assert-True (Test-Path "docs/sample-outputs/tests-success.txt") "Missing tests sample output."
    Assert-True (Test-Path "modules/zero-public-access-assignment-rg.bicep") "Missing zero public access assignment module."
  }

  It "keeps Bicep modules tagged" {
    Get-ChildItem -Path "modules" -Filter "az305-*.bicep" | ForEach-Object {
      $content = Get-Content -LiteralPath $_.FullName -Raw
      Assert-Matches $content "param tags object|targetScope = 'managementGroup'|targetScope = 'subscription'" "Module is missing tags or explicit elevated scope: $($_.FullName)"
    }
  }

  It "keeps critical modules observable" {
    @(
      "modules/az305-data-platform.bicep",
      "modules/az305-compute-app.bicep",
      "modules/az305-observability-advanced.bicep",
      "modules/az305-sentinel-soc.bicep",
      "modules/az305-zero-public-access-policy.bicep"
    ) | ForEach-Object {
      $content = Get-Content -LiteralPath $_ -Raw
      Assert-Matches $content "diagnosticSettings|OperationalInsights/workspaces|SecurityInsights|publicNetworkAccess|publicIPAddresses" "Critical module is missing observability or access controls: $_"
    }
  }
}
