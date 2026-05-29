# ADR 0002: Use Front Door For Global HTTP Entry

## Status

Accepted

## Context

AZ-305 requires choosing between regional and global load-balancing patterns.

## Decision

Use Azure Front Door for global HTTP routing, WAF, and multi-region failover.
Use Application Gateway for regional layer-7 ingress.

## Consequences

- Front Door improves global routing and edge protection.
- Application Gateway remains useful for private or regional ingress.
- Both services can coexist when global and regional controls are required.
