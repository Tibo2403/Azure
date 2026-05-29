# ADR 0005: Prefer Private Endpoints For Sensitive Services

## Status

Accepted

## Context

Sensitive data services should avoid public network exposure where practical.

## Decision

Use private endpoints for Key Vault, Storage, SQL, and container registry
scenarios where private access is enabled.

## Consequences

- Network isolation improves.
- DNS design becomes critical.
- Operational teams need clear private DNS ownership.
