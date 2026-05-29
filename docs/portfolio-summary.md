# Portfolio Summary

This repository is an Azure architecture portfolio project aligned with AZ-305.
It demonstrates infrastructure-as-code, governance, identity, monitoring,
security operations, data platform design, resiliency, migration planning, and
cost controls.

## What It Shows

- Modular Azure Bicep architecture.
- Scenario-based deployments for core AZ-305 domains.
- Production-readiness controls: CI, tests, what-if, CodeQL, secret scanning,
  OIDC, Sentinel, FinOps, management-group policy, and runbooks.
- Architecture documentation with diagrams, decision records, and study notes.

## Strong Signals For Azure Architect Roles

- Clear separation between resource-group, subscription, and management-group scopes.
- Secure-by-default design patterns: private endpoints, RBAC, Key Vault,
  managed identity, WAF, Defender, Sentinel, and policy baselines.
- Operational maturity: alerts, diagnostics, runbooks, cleanup, and cost review.
- Practical deployment ergonomics through PowerShell scripts and task runner.

## How To Present It

1. Start with `README.md` for the overview.
2. Show `docs/scenario-catalog.md` to explain breadth.
3. Open `docs/diagrams/` to explain architecture visually.
4. Show `.github/workflows/` and `tests/` for engineering discipline.
5. Use `docs/adr/` to explain architectural reasoning.
