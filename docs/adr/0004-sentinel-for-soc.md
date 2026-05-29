# ADR 0004: Use Sentinel For SOC Workflows

## Status

Accepted

## Context

Log Analytics stores telemetry, but security operations require incidents,
analytics rules, automation, and response workflows.

## Decision

Use Microsoft Sentinel for SOC-oriented scenarios and keep Log Analytics as the
underlying workspace.

## Consequences

- Incident response workflows are easier to model.
- Analytics and automation can be demonstrated as code.
- Ingestion and analytics costs must be monitored.
