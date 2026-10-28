# Review Checklists

Include only sections that apply to the scoped change set. Premise scrutiny always applies.

## Premise (always)

- [ ] User-visible outcome clear; work is not pure architectural impulse without a chosen goal
- [ ] Already-shipped mitigations acknowledged; prevention vs outcome explicit when relevant
- [ ] Scope not larger than the chosen goal requires; smaller alternative considered
- [ ] Telemetry/scale claims cited when used to justify large design
- [ ] External citations independently verifiable (primary URL/docs); mark unverifiable claims

Required report first line:

`Premise: justified | over-scoped | under-scoped | wrong-goal — <reason>`

## Code (implementation)

- [ ] Behavior matches stated intent and plan/spec when one is in scope
- [ ] Error handling and recovery paths — not happy path only
- [ ] Concurrency / race / shared-state safety where async or multi-actor
- [ ] No secrets, credentials, or private keys in the diff
- [ ] Input validation at trust boundaries
- [ ] Performance footguns (N+1, unbounded work, missing cleanup)
- [ ] Naming and patterns consistent with local conventions
- [ ] Dead code / debug leftovers absent
- [ ] Tests cover edge and failure modes for load-bearing paths — map each criterion to a test or "none"

## UI

- [ ] Accessibility: labels, keyboard, focus, contrast expectations for the change
- [ ] Empty, loading, and error states considered
- [ ] Responsive / layout regressions for touched surfaces
- [ ] Copy and user-visible strings consistent with nearby UI

## APIs / auth / data

- [ ] Authn/authz correct for new or changed endpoints
- [ ] Least privilege; no privileged secrets in client-reachable code
- [ ] Injection, SSRF, open redirect, and unsafe deserialization considered where relevant
- [ ] Rate limiting / abuse controls for new public surfaces
- [ ] Backward compatibility or coordinated consumer updates
- [ ] PII/logging hygiene

## Schemas / contracts

- [ ] Additive-first evolution; renames/removals have compat strategy
- [ ] Types/contracts updated with producers and consumers
- [ ] Migrations/rollback story when persisted shape changes
- [ ] Idempotency under retry where applicable

## Plans / specs

- [ ] Concrete decisions (no unresolved A/B menus) if marked implementation-ready
- [ ] Open questions = 0 when ready; drafts have recommended answers
- [ ] Confidence, reversibility, blast radius, risks, rollback, success metrics present as warranted
- [ ] File/contract impacts specific; verification items testable
- [ ] Run `create-plan/scripts/validate-plan.py` when that skill is available and a plan is in scope

## Skills

- [ ] Frontmatter `name` + `description` trigger correctly; body imperative and lean
- [ ] No auxiliary docs clutter; resources live under `references/` / `scripts/` / `assets/` as appropriate
- [ ] `agents/openai.yaml` quoted strings and `$skill-name` default prompt when present
- [ ] No hardcoded secrets; scripts are dependency-reasonable

## Documentation

- [ ] Paths and commands accurate for this repo
- [ ] Links resolve; overlap docs not contradictory
- [ ] Durable guidance updated when behavior changed

## Dependencies

- [ ] New deps justified; maintenance/license/size considered
- [ ] Lockfile consistent; obvious typosquatting checked
- [ ] Current API usage matches dependency version in tree (verify docs when claims are load-bearing)

## Missing behavior / risk sweep (always skim)

- [ ] Failure modes, partial failure, retries
- [ ] Hostile/abusive user behavior
- [ ] Scale 10×–1000× stress points
- [ ] Blast radius and rollback/detectability
- [ ] Tests and docs gaps called out in coverage map and "what I did not verify"
