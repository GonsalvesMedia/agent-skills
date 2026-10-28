---
name: refactor-clean
description: Refactor a codebase toward one clear owner instead of layering compatibility sediment. Use when a change reveals duplicate concepts, local adapters, obsolete owners, parallel abstractions, copied contracts, compatibility wrappers, or pressure to just tack another layer on.
---

# Refactor Clean

Move a concept to its natural owner and make consumers use that owner directly. A refactor is complete when the old shape no longer competes with the new one.

## Workflow

1. Name the duplicated concept that should have one owner: state, contract, policy, calculation, environment, API shape, UI state, or test oracle.
2. Find every owner and consumer. Treat aliases, copied constants, adapters, temporary branches, and compatibility wrappers as candidates for removal until proven necessary.
3. Search for existing mechanisms before introducing another one. Decide deliberately whether to reuse, consolidate, extract a shared core, or create a genuinely distinct owner.
4. Promote the concept to the module that would own it in a clean design. Port consumers directly to that owner.
5. Delete or collapse stale paths in the same pass when feasible. If a bridge must remain, name it as compatibility, bound its surface, and state its removal condition.
6. Verify through the consumers that used to diverge. Pin preserved behavior at consumer-facing seams, then run the relevant checks.
7. Update the active plan or durable docs with the new invariant and ownership rule—not a mechanical file inventory.

## Rules

- Prefer one shared primitive over N adapters. An adapter belongs only at an external boundary or a short-lived migration seam.
- Do not preserve unshipped scaffolding by default.
- Do not create a second computation in a test or verifier when the product can expose the canonical computed value; two derivations drift.
- Make migration scope explicit. If cleanup would widen into unrelated behavior, slice it into reviewable passes.
- Do not retain an old interface solely because it already exists. Preserve needed behavior, not accidental structure.
- Prefer depth: place substantial behavior behind the smallest honest consumer-facing interface. A seam earns an adapter only when something genuinely varies across it.
- Apply the deletion test to a proposed abstraction: if deleting it merely scatters its complexity back to callers, it has an owner; if it removes no meaningful complexity, collapse it.

## Done

Report the consolidated owner, removed or retained bridges and their removal conditions, consumers migrated, checks run, and remaining migration risk.
