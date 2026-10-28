---
name: write-tests
description: Write or review durable tests that prove real behavior. Use when adding tests for new behavior, a regression, a refactor, a flaky or brittle test, a failing test whose product behavior should not have changed, or a test diff review.
---

# Write Tests

Write tests that fail when user-visible or contract behavior breaks, not when an internal implementation, configuration value, or lucky sample changes.

## Workflow

1. Discover the repository's test runner, conventions, and narrowest focused command. Read the behavior contract, affected code, and existing nearby tests.
2. Name the observable claim: a return value, persisted state, HTTP response, rendered result, side effect, or other consumer-visible outcome. If no contract exists, surface that gap before pinning current behavior.
3. Write one focused test at a time. Run it; make it red for the intended reason when practical; then make the implementation earn green. Do not batch tests against imagined behavior.
4. Control unrelated variables: use deterministic fixtures, clocks, seeds, and boundary mocks. Mock network, filesystem, time, third-party services, or configuration lookup—not internal collaborators.
5. Assert meaningful values as well as counts for normalization, deduplication, ordering, and idempotency paths. Test the outermost practical entry point; reserve isolated unit tests for difficult pure logic.
6. For stochastic behavior, assert a distribution or invariant across a representative set of runs rather than a single lucky sample.
7. Run the focused test, adjacent relevant tests, then the repository's appropriate broader gate. Record tests not run and why.

Use a test-driven workflow (`$tdd`, if installed) when the user wants the implementation itself to proceed one red-green-refactor behavior slice at a time. This skill remains the owner of broader test design and review.

## Review rules

- Do not re-test type guarantees the compiler or schema validator already enforces.
- Do not make a live configuration value the fixture. Ask: would this fail if config changed but behavior did not?
- Do not make mocked-internal `was called with` assertions the primary proof when an observable outcome exists.
- Do not use `skipIf` to hide configuration coupling; fix the seam.
- When a test turns red after a refactor, first determine whether it encoded deleted semantics, lost a controlled variable, or used a noise-tight threshold before changing product code.
- Prove a regression test can fail when safe. If that cannot be done, say so explicitly rather than claiming coverage.
- Before describing a *suite* as thorough, mutation-test it: disable each behavior it claims to protect and require the suite to fail. An assertion that passes either way manufactures confidence and is worse than no test. Expect some to be decorative on the first pass.
- A verification result expires when either the system or the suite changes. Re-running after a code change but not after adding tests is how a true claim becomes false silently.
- When a behavior is genuinely untestable, or is a cosmetic heuristic that does not earn a test, label it as uncovered in the suite itself. That is the honest alternative to an assertion that cannot fail.

## Done

Report the behavior protected, tests added or changed, commands and results, the coverage gap if any, which behaviors were mutation-verified, and what was not verified.
