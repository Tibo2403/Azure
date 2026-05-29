Describe "AZ-305 repository production readiness" {
  It "has GitHub validation and what-if workflows" {
    Test-Path ".github/workflows/bicep-validate.yml" | Should Be $true
    Test-Path ".github/workflows/azure-whatif.yml" | Should Be $true
    Test-Path ".github/workflows/codeql.yml" | Should Be $true
    Test-Path ".github/workflows/lab-cleanup.yml" | Should Be $true
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
      "params/finops.prod.bicepparam"
    ) | ForEach-Object { Test-Path $_ | Should Be $true }
  }

  It "has operational runbooks" {
    @(
      "docs/runbooks/incident-response.md",
      "docs/runbooks/backup-restore.md",
      "docs/runbooks/sql-failover.md",
      "docs/runbooks/secret-rotation.md",
      "docs/runbooks/lab-cleanup.md"
    ) | ForEach-Object { Test-Path $_ | Should Be $true }
  }

  It "documents Well-Architected and CAF decisions" {
    Test-Path "docs/well-architected-matrix.md" | Should Be $true
    Test-Path "docs/cloud-adoption-framework.md" | Should Be $true
    Test-Path "docs/github-oidc-setup.md" | Should Be $true
    Test-Path "docs/az-305-study-notes.md" | Should Be $true
  }

  It "has architecture diagrams for core scenarios" {
    @(
      "docs/diagrams/hub-spoke.md",
      "docs/diagrams/multi-region.md",
      "docs/diagrams/data-platform.md",
      "docs/diagrams/sentinel-soc.md",
      "docs/diagrams/migration-path.md"
    ) | ForEach-Object { Test-Path $_ | Should Be $true }
  }

  It "has OIDC and cost cleanup helper scripts" {
    Test-Path "scripts/setup-github-oidc.ps1" | Should Be $true
    Test-Path "scripts/list-costly-lab-resources.ps1" | Should Be $true
  }

  It "keeps Bicep modules tagged" {
    Get-ChildItem -Path "modules" -Filter "az305-*.bicep" | ForEach-Object {
      $content = Get-Content -LiteralPath $_.FullName -Raw
      $content | Should Match "param tags object|targetScope = 'managementGroup'|targetScope = 'subscription'"
    }
  }

  It "keeps critical modules observable" {
    @(
      "modules/az305-data-platform.bicep",
      "modules/az305-compute-app.bicep",
      "modules/az305-observability-advanced.bicep",
      "modules/az305-sentinel-soc.bicep"
    ) | ForEach-Object {
      $content = Get-Content -LiteralPath $_ -Raw
      $content | Should Match "diagnosticSettings|OperationalInsights/workspaces|SecurityInsights"
    }
  }
}
