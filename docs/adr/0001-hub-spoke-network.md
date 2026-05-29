# ADR 0001: Use Hub-Spoke Network Topology

## Status

Accepted

## Context

Enterprise Azure environments need shared connectivity, centralized inspection,
and repeatable segmentation between application and data workloads.

## Decision

Use a hub-spoke topology for enterprise scenarios. The hub hosts shared services
such as Azure Firewall and private DNS. Spokes host app and data workloads.

## Consequences

- Centralized egress and DNS management become easier.
- Routing and peering are more complex than a flat VNet.
- Small labs can still use the simpler reference VNet module.
