Describe "AZ-305 repository production readiness" {
  It "has GitHub validation and what-if workflows" {
    if (-not (Test-Path ".github/workflows/bicep-validate.yml")) { throw "Missing bicep validation workflow." }
    if (-not (Test-Path ".github/workflows/azure-whatif.yml")) { throw "Missing Azure what-if workflow." }
    if (-not (Test-Path ".github/workflows/codeql.yml")) { throw "Missing CodeQL workflow." }
    if (-not (Test-Path ".github/workflows/lab-cleanup.yml")) { throw "Missing lab cleanup workflow." }
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
    ) | ForEach-Object {
      if (-not (Test-Path $_)) { throw "Missing scenario parameter file: $_" }
    }
  }

  It "has operational runbooks" {
    @(
      "docs/runbooks/incident-response.md",
      "docs/runbooks/backup-restore.md",
      "docs/runbooks/sql-failover.md",
      "docs/runbooks/secret-rotation.md",
      "docs/runbooks/lab-cleanup.md"
    ) | ForEach-Object {
      if (-not (Test-Path $_)) { throw "Missing runbook: $_" }
    }
  }

  It "documents Well-Architected and CAF decisions" {
    if (-not (Test-Path "docs/well-architected-matrix.md")) { throw "Missing Well-Architected matrix." }
    if (-not (Test-Path "docs/cloud-adoption-framework.md")) { throw "Missing CAF documentation." }
    if (-not (Test-Path "docs/github-oidc-setup.md")) { throw "Missing GitHub OIDC setup documentation." }
    if (-not (Test-Path "docs/az-305-study-notes.md")) { throw "Missing AZ-305 study notes." }
    if (-not (Test-Path "docs/scenario-catalog.md")) { throw "Missing scenario catalog." }
    if (-not (Test-Path "docs/portfolio-summary.md")) { throw "Missing portfolio summary." }
  }

  It "has architecture diagrams for core scenarios" {
    @(
      "docs/diagrams/hub-spoke.md",
      "docs/diagrams/multi-region.md",
      "docs/diagrams/data-platform.md",
      "docs/diagrams/sentinel-soc.md",
      "docs/diagrams/migration-path.md"
    ) | ForEach-Object {
      if (-not (Test-Path $_)) { throw "Missing architecture diagram: $_" }
    }
  }

  It "has OIDC and cost cleanup helper scripts" {
    if (-not (Test-Path "scripts/setup-github-oidc.ps1")) { throw "Missing OIDC setup script." }
    if (-not (Test-Path "scripts/list-costly-lab-resources.ps1")) { throw "Missing costly resource listing script." }
    if (-not (Test-Path "scripts/deploy-zero-public-access.ps1")) { throw "Missing zero public access deployment script." }
  }

  It "has ADRs for major architecture decisions" {
    @(
      "docs/adr/0001-hub-spoke-network.md",
      "docs/adr/0002-front-door-vs-application-gateway.md",
      "docs/adr/0003-compute-platform-choice.md",
      "docs/adr/0004-sentinel-for-soc.md",
      "docs/adr/0005-private-endpoints.md"
    ) | ForEach-Object {
      if (-not (Test-Path $_)) { throw "Missing ADR: $_" }
    }
  }

  It "has task runner and sample outputs" {
    if (-not (Test-Path "Taskfile.yml")) { throw "Missing Taskfile." }
    if (-not (Test-Path "docs/sample-outputs/validate-success.txt")) { throw "Missing validation sample output." }
    if (-not (Test-Path "docs/sample-outputs/tests-success.txt")) { throw "Missing tests sample output." }
    if (-not (Test-Path "modules/zero-public-access-assignment-rg.bicep")) { throw "Missing zero public access assignment module." }
  }

  It "keeps Bicep modules tagged" {
    Get-ChildItem -Path "modules" -Filter "az305-*.bicep" | ForEach-Object {
      $content = Get-Content -LiteralPath $_.FullName -Raw
      if ($content -notmatch "param tags object|targetScope = 'managementGroup'|targetScope = 'subscription'") {
        throw "Module is missing tags or explicit elevated scope: $($_.FullName)"
      }
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
      if ($content -notmatch "diagnosticSettings|OperationalInsights/workspaces|SecurityInsights|publicNetworkAccess|publicIPAddresses") {
        throw "Critical module is missing observability or access controls: $_"
      }
    }
  }
}
