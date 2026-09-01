# ADR 001: Environment Isolation

## Status

Accepted

## Context

Development and production need different capacity, protection, access, and lifecycle controls. Sharing one root configuration or state file would increase the risk that a development operation affects production.

## Decision

Use separate root directories and separate S3 state objects for development and production. Both roots will call the same reusable local modules with environment-specific inputs.

## Consequences

- Environment plans and applies remain independent.
- Production state permissions can be more restrictive.
- Module behavior stays consistent across environments.
- Some root configuration will be intentionally repeated for clarity and isolation.
