# ADR 0003: Compare App Service, Container Apps, and AKS

## Status

Accepted

## Context

Azure compute choices differ by operational complexity, scaling model, and
developer workflow.

## Decision

Use App Service for simple web apps, Container Apps for event-driven containers,
and AKS for teams needing Kubernetes control.

## Consequences

- App Service is the easiest operational model.
- Container Apps balances container flexibility with lower platform overhead.
- AKS provides the most control and the highest operational responsibility.
